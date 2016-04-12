#=
    Contents: Create, read, update and delete functions for server-side sessions.
=#


################################################################################
### Common to all databases
"Read the session_id from the specified cookie."
function read_sessionid(req::Request, cookiename::AbstractString)
    using_secure_cookies() ? get_securecookie_data(req, cookiename) : get_cookie_value(req, cookiename)
end


################################################################################
#=
    LoggedDict as database.

    Schema: ld[session_id] => Dict(...)
=#
using LoggedDicts

"""
Init session_id => session on the database and set the specified cookie to session_id.
Return: session_id
"""
function create_session(ld::LoggedDict, res::Response, cookiename::AbstractString)
    session_id = generate_session_id()
    set!(ld, session_id, Dict())
    write_to_cookie!(res, cookiename, session_id)
    session_id
end

"Delete session from database and set the specified cookie to an invalid state."
function delete_session!(ld::LoggedDict, session_id::AbstractString, res::Response, cookiename::AbstractString)
    delete!(ld, session_id)
    delete_session!(res, cookiename)
end


################################################################################
#=
    Redis as database.

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
function create_session(con::RedisConnection, res::Response, cookiename::AbstractString)
    session_id = generate_session_id()
    sadd(con, "sessions", session_id)        # Add session_id to the "sessions" Set.
    write_to_cookie!(res, cookiename, session_id)
    session_id
end


"Delete session from database and set the specified cookie to an invalid state."
function delete_session!(con::RedisConnection, session_id::AbstractString, res::Response, cookiename::AbstractString)
    delete_session_from_database!(con, session_id)
    delete_session!(res, cookiename)
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


function get(con::RedisConnection, keys...)
    k = construct_keypath(false, keys...)
    get(con, k)
end


function set!(con::RedisConnection, keys_value...)
    k = construct_keypath(true, keys_value...)
    set(con, k, keys_value[length(keys_value)])    # Set keypath => value
end


# EOF
