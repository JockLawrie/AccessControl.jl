#=
    Contents: Non app-specific handlers.
=#


"""
Process login credentials.
Login request must be a POST request.
If login is successful, redirect to success_redirect, else return bad_request.
"""
function login!(req, res, acdata, success_redirect::AbstractString)
    if req.method == "POST"                                           # Require that login requests are POST requests
        username, password = extract_username_password(req)
	if login_credentials_are_valid(username, password, acdata)    # Successful login: Redirect
	    redirect!(res, success_redirect)
	    create_secure_session_cookie(username, res, "sessionid")
	else                                                          # Unsuccessful login: Return 400: Bad Request
	    badrequest!(res)
	end
    else
	badrequest!(res)
    end
end


"User has clicked the logout button/link: Redirect to redirect_path."
function logout!(req, res, redirect_path::AbstractString)
    username = get_session_cookie_data(req, "sessionid")
    is_not_logged_in(username) && (notfound!(res); return)
    redirect!(res, redirect_path)
    invalidate_cookie!(res, "sessionid")
end


"User has submitted a new password."
function user_reset_password!(req, res, acdata, success_redirect::AbstractString)
    username = get_session_cookie_data(req, "sessionid")
    is_not_logged_in(username) && (notfound!(res); return)
    if req.method == "POST"
        current_pwd, new_pwd, new_pwd2 = extract_currpwd_newpwd_newpwd2(req)
        if login_credentials_are_valid(username, current_pwd, acdata) && new_pwd == new_pwd2    # Successful password reset: Redirect
            redirect!(res, success_redirect)
	    set_password!(username, new_pwd)
        else                                                          # Unsuccessful password reset: Return 400: Bad Request
            badrequest!(res)
        end
    else
        badrequest!(res)
    end
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
