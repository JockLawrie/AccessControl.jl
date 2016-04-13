#=
    Contents: Create, read, update and delete functions for server-side sessions that use a LoggedDict as the database.

    Schema: ld[session_id] => Dict(...)
=#
using LoggedDicts

"""
Init session_id => session on the database and set the specified cookie to session_id.
Return: session_id
"""
function create_session(sessions::LoggedDict, username::AbstractString, res::Response, cookiename::AbstractString)
    get_n_sessions(username) >= config[:session][:max_n_sessions] && return
    session_id = generate_session_id()
    set!(sessions, session_id, Dict{Symbol, Any}(:username => username))
    add_sessionid_to_user!(username, session_id)
    write_to_cookie!(res, cookiename, session_id)
    session_id
end


"Delete session from database and set the specified cookie to an invalid state."
function delete_session!(sessions::LoggedDict, session_id::AbstractString, res::Response, cookiename::AbstractString)
    delete!(sessions, session_id)
    remove_sessionid_from_user!(username, session_id)
    delete_session!(res, cookiename)
end


"Returns: true if session_id exists in the server-side data store."
function session_is_valid(sessions::LoggedDict, session_id::AbstractString)
    haskey(sessions, session_id)
end


# EOF
