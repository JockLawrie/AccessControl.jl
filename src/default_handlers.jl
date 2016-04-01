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
	if login_credentials_are_valid(username, password, acdata)    # Successful login: Redirect to members_only page
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
function logout!(res, redirect_path::AbstractString)
    redirect!(res, redirect_path)
    setcookie!(res, "sessionid", utf8(""), Dict("Max-Age" => utf8("0")))
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
