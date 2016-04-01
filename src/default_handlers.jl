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
    invalidate_cookie!(res, "sessionid")
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


################################################################################
#= Macro version of handlers.

   These are useful for inserting into existing handlers to enable early returns if a check fails. For example:
       function myhandler(req, res)
	   is_not_logged_in(username) && @notfound!(res)
	   # existing handler code here
       end
   This handler checks whether the user is logged in.
   If not, return notfound!(res), else continue to the existing handler code.
   This pattern is useful for checking if a user is authorized to access a resource and determining behaviour if the check fails.
=#
#=
macro notfound!(res)
    return quote
	notfound!($res)
	return $res
    end
end


macro badrequest!(res)
    return quote
	badrequest!($res)
	return $res
    end
end


macro redirect!(res, destpath)
    return quote
	redirect!($res, $destpath)
	return $res
    end
end
=#

# EOF
