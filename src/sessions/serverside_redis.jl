#=
    Contents: Create, read, update and delete functions for server-side sessions that use Redis as a database.

    Notes:
    1. Key paths are transformed from (k1, k2, k3) to k1:k2:k3.
    2. Schema:
       - "sessions" => Set(session_id1, ...),      set of current valid session_ids.
       - "session:$(session_id):$(keypath)" => v,  key-value pairs for session_id.
       - "session:keypaths" => Set(keypaths...),   exploits the fact that session fields come from a common app-specific set.
    3. Example:
       - set!(con, session_id, k1, k2, k3, v) = set(con, "session:$session_id:$k1:$k2:k3", v)
    4. Maintaining key_paths allows the delete_session! function to work.
=#
using Redis


"""
Init session_id => session on the database and set the specified cookie to session_id.
Return: session_id
"""
function session_create!(con::RedisConnection, username::AbstractString, res::Response, cookiename::AbstractString)
    get_n_sessions(username) >= config[:session][:max_n_sessions] && return
    session_id = generate_session_id()
    sadd(con, "sessions", session_id)                     # Add session_id to the "sessions" Set
    set(con, "session:$session_id:username", username)    # Add username to the session data
    sadd(con, "session:keypaths", "username")             # Add "username"  to the "session:keypaths" Set
    if haskey(config[:session], :timeout)                 # Add "lastvisit" to the "session:keypaths" Set
	sadd(con, "session:keypaths", "lastreq")
	update_lastreq!(con, session_id)
    end
    add_sessionid_to_user!(username, session_id)
    write_to_cookie!(res, cookiename, session_id)
    session_id
end


"Delete session from database and set the specified cookie to an invalid state."
function session_delete!(con::RedisConnection, session_id::AbstractString, res::Response, cookiename::AbstractString)
    username = get(con, "session:$session_id:username")
    remove_sessionid_from_user!(username, session_id)
    delete_session_from_database!(con, session_id)
    session_delete!(res, cookiename)
end


function delete_session_from_database!(con::RedisConnection, session_id::AbstractString)
    # Delete session fields
    kys = smembers(con, "session:keypaths")
    for k in kys
	del(con, "session:$session_id:$k")
    end

    # Delete the session from the "sessions" Set
    srem(con, "sessions", session_id)
end


function delete_all_sessions_from_database!(con::RedisConnection)
    session_ids = smembers(con, "sessions")
    for session_id in session_ids
	delete_session_from_database!(con, session_id)
    end
end


function session_is_valid(con::RedisConnection, session_id::AbstractString)
    result = sismember(con, "sessions", session_id)
    if haskey(config[:session], :timeout)
        dt_str = session_get(con, session_id, "lastreq")
	if dt_str == nothing
	    result = false
	else
	    dt = DateTime(dt_str)
	    if dt + Dates.Second(config[:session][:timeout]) < now()
		result = false    # Session has timed out
	    end
	end
    end
    result
end


function update_lastreq!(con::RedisConnection, session_id::AbstractString)
    set(con, "session:$session_id:lastreq", string(now()))
end


"""
Returns: key path defined by keys..., converted to Redis format.

Example 1:
    - INPUT:  keys_value... = k1, k2, k3, v
    - OUTPUT: key_path = "k1:k2:k3"

Example 2:
    - INPUT:  keys_value... = k1, k2, k3 (NO VALUE...has_value == false)
    - OUTPUT: key_path = "k1:k2:k3"
"""
function construct_keypath(has_value::Bool, keys_value...)
    nkeys = length(keys_value)
    if has_value
	nkeys -= 1
    end
    assert(nkeys >= 1)
    io    = IOBuffer()
    print(io, "$(keys_value[1])")
    if nkeys >= 2
	for i = 2:nkeys
	    print(io, ":$(keys_value[i])")
	end
    end
    takebuf_string(io)
end


function session_get(con::RedisConnection, session_id, keys...)
    k = construct_keypath(false, keys...)
    get(con, "session:$session_id:$k")
end


function session_set!(con::RedisConnection, session_id, keys_value...)
    k1 = keys_value[1]
    (k1 == "lastreq" || k1 == "username") && return                       # Forbid changing username or lastreq
    k = construct_keypath(true, keys_value...)
    sadd(con, "session:keypaths", k)                                      # Add key path to the set of key paths
    set(con, "session:$session_id:$k", keys_value[length(keys_value)])    # Set keypath => value
end


# EOF
