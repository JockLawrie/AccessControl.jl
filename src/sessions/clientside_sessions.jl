#=
    Contents: Create, read and delete functions for client-side sessions.
=#

"Returns a session object with 'id' => session_id, where session_id is randomly generated."
function create_session()
    Dict("id" => base64encode(csrng(32)))
end

"Read the session from the specified cookie."
function read_session(req::Request, cookiename::AbstractString)
    s = ""
    if using_secure_cookies()
	s = get_securecookie_data(req, cookiename)
    else
	s = get_cookie_value(req, cookiename)
    end
    s == "" ? s : JSON.parse(s)
end

"Write the session object to the specified cookie."
function write_session(res::Response, cookiename, session::Dict)
    s = JSON.json(session)
    using_secure_cookies() ? set_securecookie!(res, cookiename, s) : setcookie!(res, cookiename, s)
end


"Set the specified cookie to an invalid state."
function delete_session!(res::Response, cookiename::AbstractString)
    invalidate_cookie!(res, cookiename)
end


# EOF
