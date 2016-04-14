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


function session_is_valid(cp::ConnectionPool, session_id::AbstractString)
    con = get_connection!(cp)
    session_is_valid(con, username)
    release!(cp, con)
end


"""
Init session_id => session on the database and set the specified cookie to session_id.
Return: session_id
"""
function session_create!(res::Response, username::AbstractString)
    cookiename = config[:session][:cookiename]
    session_create!(config[:session][:datastore], username, res, cookiename)
end


function session_create!(cp::ConnectionPool, username::AbstractString, res::Response, cookiename::AbstractString)
    con = get_connection!(cp)
    session_id = session_create!(con, username, res, cookiename)
    release!(cp, con)
    session_id
end


"Delete session from database and set the specified cookie to an invalid state."
function session_delete!(res::Response, session_id::AbstractString)
    session_delete!(config[:session][:datastore], res, session_id)
end


function session_delete!(cp::ConnectionPool, session_id::AbstractString, res::Response, cookiename::AbstractString)
    con = get_connection!(cp)
    session_delete!(con, session_id, res, cookiename)
    release!(cp, con)
end


function session_get(session_id, keys...)
    session_get(config[:session][:datastore], session_id, keys...)
end


function session_get(cp::ConnectionPool, session_id::AbstractString, keys...)
    con = get_connection!(cp)
    v = session_get(con, session_id, keys...)
    release!(cp, con)
    v
end


function session_set!(session_id, keys_value...)
    session_set!(config[:session][:datastore], session_id, keys_value...)
end


function session_set!(cp::ConnectionPool, session_id::AbstractString, keys_value...)
    con = get_connection!(cp)
    session_set!(con, session_id, keys_value...)
    release!(cp, con)
end


# EOF
