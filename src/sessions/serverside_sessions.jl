#=
    Contents: Create, read, update and delete functions for server-side sessions.
=#

session_id = create_session(con, res, "id")    # Init "id" => session_id on the database and set the "id" cookie to session_id
session_id = read_sessionid(req, "id")         # Read the session_id from the "id" cookie
get(con, keys...)                              # Read the value located at the path defined by keys...
set!(con, keys..., value)                      # Set the value located at the path defined by keys...
delete_session!(con, session_id, res, "id")    # Delete session from database and set the response's "id" cookie to an invalid state


################################################################################
### LoggedDict as database


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
