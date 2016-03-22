#=

Contents: Main routine for AccessControl.jl

=#


"""
INPUT:
1. 0, 1 or 2 command line arguments denoting passwd and security_level respectively.
"""
function access_control()
    get_passwd_seclvl()
    add_admin_page()
end


function get_passwd_seclvl()
    nargs = size(ARGS, 1)
    if nargs == 1
        passwd = ARGS[1]
        seclvl = "1_admin"
    elseif nargs == 2
        seclvl = ARGS[2]
        seclvl = "2_admin_https"
    elseif nargs > 2
	error("Too many command line argmuents.")
    end
    if passwd != ""
	if !password_is_permissible(passwd)
	    error("Password is not permissible.")
        end
    end
end


function add_admin_page()
    if seclvl != "0_no_admin"
        paths["/admin"] = admin_handler
    end
    if seclvl == "2_admin_encrypted"
	# Error if protocol is not https
    end
end


# EOF
