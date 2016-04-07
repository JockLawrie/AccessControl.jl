#=
    Contents: Non app-specific handlers.
=#


"""
Process login credentials.
Login request must be a POST request.
If login is successful, redirect to success_redirect, else return bad_request.
"""
function login!(req, res)
    acdata = cfg["acdata"]
    success_redirect = cfg["login_cfg"]["success_redirect"]
    if req.method == "POST"                                           # Require that login requests are POST requests
        username, password = extract_username_password(req)
	if login_credentials_are_valid(username, password, acdata)    # Successful login: Redirect
	    redirect!(res, success_redirect)
	    create_secure_session_cookie(username, res, "sessionid")
	else                                                          # Unsuccessful login: Return 400: Bad Request
	    msg = cfg["login_cfg"]["fail_msg"]
	    res.data = "<script><alert($(msg));/script>"
	end
    else
	badrequest!(res)
    end
end


"User has clicked the logout button/link: Redirect to redirect_path."
function logout!(req, res)
    redirect_path = cfg["logout_cfg"]["redirect"]
    username = get_session_cookie_data(req, "sessionid")
    is_not_logged_in(username) && (notfound!(res); return)
    redirect!(res, redirect_path)
    invalidate_cookie!(res, "sessionid")
end


"""
User has submitted a new password.

Lockout occurs if the supplied original password is wrong too many times (defined by cfg["pwdreset_cfg"]).
"""
function user_reset_password!(req, res, acdata, success_redirect::AbstractString)
    acdata = cfg["acdata"]
    success_redirect = cfg["pwdreset"]["success_redirect"]
    username = get_session_cookie_data(req, "sessionid")
    is_not_logged_in(username) && (notfound!(res); return)
    if req.method == "POST"
        current_pwd, new_pwd, new_pwd2 = extract_currpwd_newpwd_newpwd2(req)
        if login_credentials_are_valid(username, current_pwd, acdata) && new_pwd == new_pwd2    # Successful password reset: Redirect
            redirect!(res, success_redirect)
	    set_password!(username, new_pwd)
        else                                                          # Unsuccessful password reset: Return 400: Bad Request
	    msg = cfg["pwdreset_cfg"]["fail_msg"]
	    res.data = "<script><alert($(msg));/script>"
        end
    else
        badrequest!(res)
    end
end


"Page displayed when user clicks Reset Password link."
function reset_password!(req, res)
    username = get_session_cookie_data(req, "sessionid")
    is_not_logged_in(username) && (notfound!(res); return)
    res.data = "<h2>Password reset.</h2>
                <br>
		<form action='user_reset_password' method='post'>
	            Current password:<br>
	            <input type='password' id='current_pwd' name='current_pwd'/>
	            <br>
	            New password:<br>
	            <input type='password' id='new_pwd' name='new_pwd'/>
	            <br>
	            Retype new password:<br>
	            <input type='password' id='new_pwd2' name='new_pwd2'/>
	            <br>
                    <input type='submit' value='Reset Password'/>
		</form>"
end

function notfound!(res)
    res.status = 404
    res.data   = "Requested resource not found."
end


function badrequest!(res)
    res.data   = "Bad request"
    res.status = 400
end


"Redirect user to destination_path."
function redirect!(res, destination_path::AbstractString)
    res.status = 303
    res.headers["Location"] = destination_path
end


# EOF
