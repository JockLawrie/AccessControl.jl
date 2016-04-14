#=
    Contents: Non app-specific handlers.
=#


"""
Process login credentials.
Login request must be a POST request.
If login is successful, redirect to success_redirect, else return bad_request.
"""
function login!(req, res)
    acdata           = config[:acdata]
    success_redirect = config[:login][:success_redirect]
    if req.method == "POST"                                           # Require that login requests are POST requests
        username, password = extract_username_password(req)
	if login_credentials_are_valid(username, password, acdata)    # Successful login: Redirect
	    redirect!(res, success_redirect)
	    if config[:session][:datastore] == :cookie
		session = session_create!(username)
		session_write!(res, session)
	    else
		session_create!(res, username)
	    end
	else                                                          # Unsuccessful login: Return fail message
	    msg = config[:login][:fail_msg]
	    res.data = "<script><alert($(msg));/script>"
	end
    else
	badrequest!(res)
    end
end


"User has clicked the logout button/link: Redirect to redirect_path."
function logout!(req, res)
    is_not_logged_in(req) && (notfound!(res); return)
    redirect!(res, config[:logout][:redirect])
    session_delete!(res)
end


"""
User has submitted a new password.

Lockout occurs if the supplied original password is wrong too many times (defined by cfg["pwdreset_cfg"]).
"""
function process_pwdreset!(req, res)
    is_not_logged_in(req) && (notfound!(res); return)
    acdata           = config[:acdata]
    success_redirect = config[:pwdreset][:success_redirect]
    if req.method == "POST"
        current_pwd, new_pwd, new_pwd2 = extract_currpwd_newpwd_newpwd2(req)
	username = get_username(req)
        if login_credentials_are_valid(username, current_pwd, acdata) && new_pwd == new_pwd2    # Successful password reset: Redirect
            redirect!(res, success_redirect)
	    set_password!(username, new_pwd)
        else                                                # Unsuccessful password reset: Return 400: Bad Request
	    msg = config[:pwdreset][:fail_msg]
	    res.data = "<script><alert($(msg));/script>"
        end
    else
        badrequest!(res)
    end
end


"Page displayed when user clicks Reset Password link."
function reset_password!(req, res)
    is_not_logged_in(req) && (notfound!(res); return)
    res.data = pwdreset_form()
end


# EOF
