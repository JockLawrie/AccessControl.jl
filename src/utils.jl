#=
    Contents: Non app-specific utilities.
=#


"""
Returns true if username and password are valid.

INPUT:
- acdata: Either the store of Access Control data, or a connection to it.
          For example, an intra-process Dict or a connection to a database from a connection pool.
"""
function login_credentials_are_valid(username::AbstractString, password::AbstractString, acdata)
    salt, hashed_pwd = get_salt_hashedpwd(username, acdata)     # Depends on datastore (acdata)...user to implement.
    password_is_valid(password, salt, hashed_pwd)
end


"Returns: username and password extracted from login POST request."
function extract_username_password(req)
   qry      = bytestring(req.data)        # query = "username=xxx&password=yyy"
   dct      = parsequerystring(qry)       # Dict("username" => xxx, "password" => yyy)
   username = dct["username"]
   password = dct["password"]
   username, password
end


"Returns true if req has a valid 'sessionid' cookie."
function is_logged_in(req::Request)
    username = get_session_cookie_data(req, "sessionid")    # Returns "" if sessionid cookie doesn't exist
    is_logged_in(username)
end


function is_logged_in(username::AbstractString)
    username == "" ? false : true
end


is_not_logged_in(uname_or_req) = !is_logged_in(uname_or_req)


# EOF
