#=
    Contents: Functions for server-side sessions that are common to all databases.
=#

"Read the session_id from the specified cookie."
function read_sessionid(req::Request, cookiename::AbstractString)
    using_secure_cookies() ? get_securecookie_data(req, cookiename) : get_cookie_value(req, cookiename)
end

read_sessionid(req::Request) = read_sessionid(req, config[:session][:cookiename])


"Add session_id to user record in acdata."
function add_sessionid_to_user!(username::AbstractString, session_id::AbstractString)
    add_sessionid_to_user!(config[:acdata], username, session_id)
end 


"Remove session_id from user record in acdata."
function remove_sessionid_from_user!(username::AbstractString, session_id::AbstractString)
    remove_sessionid_from_user!(config[:acdata], username, session_id)
end 


# EOF
