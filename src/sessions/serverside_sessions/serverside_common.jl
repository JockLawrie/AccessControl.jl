#=
    Contents: Functions for server-side sessions that are common to all databases.
=#

"Read the session_id from the specified cookie."
function read_sessionid(req::Request, cookiename::AbstractString)
    using_secure_cookies() ? get_securecookie_data(req, cookiename) : get_cookie_value(req, cookiename)
end

read_sessionid(req::Request) = read_sessionid(req, config[:session][:cookiename])


"Returns: true if session_id exists in the server-side data store."
function session_is_valid(session_id::AbstractString)
    session_is_valid(config[:session], session_id)
end


"""
Init session_id => session on the database and set the specified cookie to session_id.
Return: session_id
"""
function create_session(username::AbstractString, res::Response)
    tp = typeof(config[:session][:datastore])
    cookiename = config[:session][:cookiename]
    create_session(tp, username, res, cookiename)
end


"Delete session from database and set the specified cookie to an invalid state."
function delete_session!(session_id::AbstractString, res::Response)
    tp = typeof(config[:session][:datastore])
    cookiename = config[:session][:cookiename]
    delete_session(tp, username, res, cookiename)
end


# EOF
