#=
    Contents: Utils for handling authentication.
=#


"""
Returns true if username and password are valid.

INPUT:
- acdata: Either the store of Access Control data, or a connection to it.
          For example, an intra-process Dict or a connection to a database from a connection pool.
"""
function login_credentials_are_valid(username::AbstractString, password::AbstractString, acdata)
    salt, hashed_pwd = get_salt_hashedpwd(acdata, username)
    password_is_valid(password, salt, hashed_pwd)
end


"Returns: username and password extracted from login POST request."
function extract_username_password(req)
   qry = bytestring(req.data)        # query = "username=xxx&password=yyy"
   dct = JSON.parse(qry)             # Dict("username" => xxx, "password" => yyy)
   dct["username"], dct["password"]
end


"""
Returns: username, current password and new password extracted from process_pwdreset POST request.

Notes:
1. New password is supplied twice, via new_pwd and new_pwd2.
"""
function extract_currpwd_newpwd_newpwd2(req)
    qry = bytestring(req.data)
    dct = JSON.parse(qry)    # Dict("form_id" => "pwdreset", "nonce" => nonce, "current_pwd" => yyy, "new_pwd" => zzz, "new_pwd2" => www)
    dct["form_id"], dct["nonce"], dct["current_pwd"], dct["new_pwd"], dct["new_pwd2"]
end


"Returns true if req has a valid 'sessionid' cookie."
function is_logged_in(req::Request)
    result     = false
    cookiename = config[:session][:cookiename]
    sessions   = config[:session][:datastore]
    if sessions == :cookie
	result = read_session(req, cookiename) != ""
    else
	session_id = read_sessionid(req, cookiename)           # Read session_id from cookie
	result     = session_is_valid(sessions, session_id)    # Check session_id against server-side session data
    end
    result
end

is_not_logged_in(req) = !is_logged_in(req)


"Returns: username, derived from request regardless of whether the session is client-side or server-side."
function get_username(req::Request)
    username = ""
    if config[:session][:datastore] == :cookie
	session  = session_read(req)
	username = session["username"]
    else
	session_id = read_sessionid(req)
	username   = session_get(session_id, "username")
    end
    username
end


"""
Returns: Redirect location according to config.

The config either specifies:
- A location. Example: "/home", or
- A function of the user: Example: f(username) = '/members/get_role(username)'
"""
function get_redirect_location(username::AbstractString, config_key1::Symbol, config_key2::Symbol)
    loc = ""
    _redirect = config[config_key1][config_key2]
    if typeof(_redirect) == Function
	loc = _redirect(username)
    else
	loc = _redirect
    end
    loc
end

# EOF
