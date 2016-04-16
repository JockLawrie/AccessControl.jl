#=
    Contents: Non app-specific handlers.
=#


"""
Process login credentials.
Login request must be a POST request.
If login is successful, redirect to success_redirect, else return bad_request.
"""
function login!(req, res)
    acdata = config[:acdata]
    if req.method == "POST"                                           # Require that login requests are POST requests
        username, password = extract_username_password(req)
	if login_credentials_are_valid(username, password, acdata)    # Successful login: Redirect
	    # Create session
	    if config[:session][:datastore] == :cookie
		session = session_create!(username)
		session_write!(res, session)
	    else
		session_create!(res, username)
	    end

	    # Redirect
	    res.data = get_redirect_location(username, :login, :success_redirect)
	else                                                          # Unsuccessful login: Return fail message
	    res.status = 400    # Bad request
	    res.data   = config[:login][:fail_msg]
	end
    else
	badrequest!(res)
    end
end


"User has clicked the logout button/link: Redirect to redirect_path."
function logout!(req, res)
    is_not_logged_in(req) && (notfound!(res); return)
    username = get_username(req)
    loc      = get_redirect_location(username, :logout, :redirect)
    redirect!(res, loc)
    if config[:session][:datastore] == :cookie
	session_delete!(res)
    else
	session_id = read_sessionid(req)
	session_delete!(res, session_id)
    end
end


"""
User has submitted a new password.

Lockout occurs if the supplied original password is wrong too many times (defined by cfg["pwdreset_cfg"]).
"""
function process_pwdreset!(req, res)
    is_not_logged_in(req) && (notfound!(res); return)
    acdata = config[:acdata]
    if req.method == "POST"
        current_pwd, new_pwd, new_pwd2 = extract_currpwd_newpwd_newpwd2(req)
	username = get_username(req)
        if login_credentials_are_valid(username, current_pwd, acdata) && new_pwd == new_pwd2    # Successful password reset: Redirect
	    set_password!(username, new_pwd)
	    res.data = get_redirect_location(username, :pwdreset, :success_redirect)
        else                                                # Unsuccessful password reset: Return 400: Bad Request
	    res.status = 400    # Bad request
	    res.data   = config[:pwdreset][:fail_msg]
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
