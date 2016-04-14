#=
    Contents: Create, read, update and delete functions for server-side sessions that use a LoggedDict as the database.

    Schema: ld[session_id] => Dict(...)
=#
using LoggedDicts

"""
Init session_id => session on the database and set the specified cookie to session_id.
Return: session_id
"""
function session_create!(sessions::LoggedDict, username::AbstractString, res::Response, cookiename::AbstractString)
    get_n_sessions(username) >= config[:session][:max_n_sessions] && return
    session_id = generate_session_id()
    set!(sessions, session_id, Dict{AbstractString, Any}("username" => username))
    haskey(config[:session], :timeout) && set!(sessions, session_id, "lastvisit", string(now()))
    add_sessionid_to_user!(username, session_id)
    write_to_cookie!(res, cookiename, session_id)
    session_id
end


"Delete session from database and set the specified cookie to an invalid state."
function session_delete!(sessions::LoggedDict, res::Response, session_id::AbstractString)
    username = get(sessions, session_id, "username")
    delete!(sessions, session_id)
    remove_sessionid_from_user!(username, session_id)
    session_delete!(res)
end


"Returns: true if session_id exists in the server-side data store."
function session_is_valid(sessions::LoggedDict, session_id::AbstractString)
    haskey(sessions, session_id)
end


function session_get(sessions::LoggedDict, session_id, keys...)
    get(sessions, session_id, keys...)
end


function session_set!(sessions::LoggedDict, session_id, keys...)
    set!(sessions, session_id, keys...)
end


# EOF
