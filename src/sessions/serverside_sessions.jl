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
### LoggedDict as database
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


# EOF
