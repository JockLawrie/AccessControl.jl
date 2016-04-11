#=
    Contents: Functions for session management.
=#


#=
  Default session config
    - securecookies::Bool   If true, use secure cookies instead of plain-text cookies
    - max_n_sessions::Int   Max number of simultaneous sessions per user
    - timeout::Int          Number of seconds between requests that results in a session timeout
=#
session_config = Dict("securecookies" => true, "max_n_sessions" => 1, "timeout" => 600)


function create_session()
    session_id = bytestring(csrng(32))
    Dict("id" => session_id)
end


function write_sessionid(res, cookiename, session_id)
    !session_config["serverside"] && error("Cannot write client-side session ID directly to cookie. Write entire session instead.")
    session_config["securecookies"] ? set_securecookie!(res, "id", session_id) : setcookie!(res, cookiename, session_id)
end


function read_sessionid(req, cookiename)
    data = get_securecookie_date(req, cookiename)
    session_config["serverside"] ? data : data["id"]
end

function write_session(res::Response, cookiename, session::Dict, secure=true)
    data = JSON.json(session)
    if secure
	set_securecookie!(res, "id", data)
    else
	setcookie!(res, cookiename, data)
    end
end


# EOF
