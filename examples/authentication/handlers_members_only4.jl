#=
    Contents: Handlers for members_only2.jl.
=#


########################################################################
# Non app-specific utilities
########################################################################
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


function is_logged_in(username::AbstractString)
    username == "" ? false : true
end
is_not_logged_in(username) = !is_logged_in(username)


########################################################################
# Non app-specific handlers
########################################################################
"""
Process login credentials.
Login request must be a POST request.
If login is successful, redirect to success_redirect, else return bad_request.
"""
function login!(req, res, acdata, success_redirect::AbstractString)
    if req.method == "POST"                                           # Require that login requests are POST requests
        username, password = extract_username_password(req)
	if login_credentials_are_valid(username, password, acdata)    # Successful login: Redirect to members_only page
	    redirect!(res, success_redirect)
	    create_secure_session_cookie(username, res, "sessionid")
	else                                                          # Unsuccessful login: Return 400: Bad Request
	    bad_request!(res)
	end
    else
	bad_request!(res)
    end
end


"User has clicked the logout button/link: Redirect to redirect_path."
function logout!(res, redirect_path::AbstractString)
    redirect!(res, redirect_path)
    setcookie!(res, "sessionid", utf8(""), Dict("Max-Age" => utf8("0")))
end


function notfound!(res)
    res.status = 404
    res.data   = "Requested resource not found."
end


function bad_request!(res)
    res.data   = "Bad request"
    res.status = 400
end


"Redirect user to destination_path."
function redirect!(res, destination_path::AbstractString)
    res.status = 303
    res.headers["Location"] = destination_path
end


########################################################################
# App-specific handlers
########################################################################
function home_with_login_form!(res)
    s = "<p>This is the home page. Anyone can visit here.</p>
         <br>
	 <br>
	 <form action='login' method='post'>
	     Username:<br>
	     <input type='text' id='username' name='username'/>
	     <br>
	     Password:<br>
	     <input type='password' id='password' name='password'/>
	     <br>
	     <input type='submit' value='Login'/>
	 </form>"
    res.data = s
end


"Members only message with a logout link."
function members_only!(req, res)
    username = get_session_cookie_data(req, "sessionid")
    is_not_logged_in(username) && @notfound(res)
    s = "<p>This page displays information for members only.</p>
         <br>
         <form action='logout' method='post'>
	     <input type='submit' value='Logout'/>
         </form>"
    res.data = s
end
