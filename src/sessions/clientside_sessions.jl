#=
    Contents: Create, read and delete functions for client-side sessions.
=#


"""
Returns a Dict with:
- 'id'        => session_id, which is randomly generated using a cryptographically secure RNG.
- 'username'  => username 
"""
function create_session(username::AbstractString)
    result             = Dict{AbstractString, Any}()
    result["id"]       = generate_session_id()
    result["username"] = username
    result
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
function write_session!(res::Response, cookiename::AbstractString, session::Dict)
    write_to_cookie!(res, cookiename, JSON.json(session))
end


"Set the specified cookie to an invalid state."
function delete_session!(res::Response, cookiename::AbstractString)
    invalidate_cookie!(res, cookiename)
end


################################################################################
### Utils

function generate_session_id()
    base64encode(csrng(config[:session][:id_length]))
end

function write_to_cookie!(res::Response, cookiename::AbstractString, data::AbstractString)
    using_secure_cookies() ? set_securecookie!(res, cookiename, data) : setcookie!(res, cookiename, data)
end


# EOF
