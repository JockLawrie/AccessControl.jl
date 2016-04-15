#=
    Contents: Utilities for authorization.
=#


function has_role(req::Request, role::AbstractString)
    result = false
    if is_logged_in(req)
	username = get_username(req)
	result   = has_role(username, role)
    end
    result
end


# EOF
