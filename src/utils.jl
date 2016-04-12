#=
    Contents: Non app-specific utilities.
=#

"Update config and trigger update of downstream values."
function update_config!(k1::Symbol, k2::Symbol, val)
    config[k1][k2] = val
    if k1 == :securecookie
	update_securecookie_config!(k2)
    end
end


"Returns true if the application is using secure cookies."
function using_secure_cookies()
    haskey(config, :securecookie)
end


"Cryptographically secure RNG"
function csrng(numbytes::Integer)
    entropy = MbedTLS.Entropy()
    rng     = MbedTLS.CtrDrbg()
    MbedTLS.seed!(rng, entropy)
    rand(rng, numbytes)
end

################################################################################
################################################################################

"""
Returns true if username and password are valid.

INPUT:
- acdata: Either the store of Access Control data, or a connection to it.
          For example, an intra-process Dict or a connection to a database from a connection pool.
"""
function login_credentials_are_valid(username::AbstractString, password::AbstractString, acdata)
    salt, hashed_pwd = get_salt_hashedpwd(username, acdata)     # Depends on datastore (acdata)
    password_is_valid(password, salt, hashed_pwd)
end


"Returns: username and password extracted from login POST request."
function extract_username_password(req)
   qry      = bytestring(req.data)        # query = "username=xxx&password=yyy"
   dct      = parsequerystring(qry)       # Dict("username" => xxx, "password" => yyy)
   dct["username"], dct["password"]
end


"""
Returns: username, current password and new password extracted from user_reset_password POST request.

Notes:
1. New password is supplied twice, via new_pwd and new_pwd2.
"""
function extract_currpwd_newpwd_newpwd2(req)
    qry = bytestring(req.data)
    dct = parsequerystring(qry)    # Dict("current_pwd" => yyy, "new_pwd" => zzz, "new_pwd2" => www)
    dct["current_pwd"], dct["new_pwd"], dct["new_pwd2"]
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
