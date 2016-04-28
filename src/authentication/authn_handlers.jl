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
	    if using_clientside_sessions()
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
    if using_clientside_sessions()
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
        form_id, nonce, current_pwd, new_pwd, new_pwd2 = extract_currpwd_newpwd_newpwd2(req)

	# Check whether nonce is valid
	nonce_is_valid = false
	if using_clientside_sessions()
	    session = session_read(req)
	    dct     = session["forms"]
	    if haskey(dct, form_id) && dct[form_id] == nonce
		nonce_is_valid = true
	    end
	else
	    session_id = read_sessionid(req)
	    if nonce == session_get(session_id, "forms", form_id)
		nonce_is_valid = true
	    end
	end

	# If nonce is valid then check login credentials
	if nonce_is_valid
	    username  = get_username(req)
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
    else
        badrequest!(res)
    end
end


"Page displayed when user clicks Reset Password link."
function reset_password!(req, res)
    is_not_logged_in(req) && (notfound!(res); return)
    if using_clientside_sessions()
	session  = session_read(req)
	res.data = pwdreset_form(session)
    else
	session_id = read_sessionid(req)
	res.data   = pwdreset_form(session_id)
    end
end


# EOF
