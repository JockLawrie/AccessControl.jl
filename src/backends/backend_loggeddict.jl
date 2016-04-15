#=
    Contents: Function that generates getters/setters for cfg["acdata"] of typew LoggedDict

    Notes:
    1. The scheme for acdata::LoggedDict is: username => Dict("password" => password, "roles" => Set{AbstractString}).
=#


using LoggedDicts


function create_user!(acdata::LoggedDict, username::AbstractString, password::AbstractString, roles::Set)
    set!(acdata,  username, Dict{Symbol, Any}())    # username => Dict{Symbol, Any}
    set_password!(acdata, username, password)
    set!(acdata, username, :roles, roles)
    set!(acdata, username, :session_ids, Set{AbstractString}())
end


function delete_user!(acdata::LoggedDict, username::AbstractString)
    if haskey(acdata, username)
	delete!(acdata, username)
    end
end


function add_sessionid_to_user!(acdata::LoggedDict, username::AbstractString, session_id::AbstractString)
    push!(acdata, username, :session_ids, session_id)
end


function remove_sessionid_from_user!(acdata::LoggedDict, username::AbstractString, session_id::AbstractString)
    pop!(acdata, username, :session_ids, session_id)
end


function get_n_sessions(acdata::LoggedDict, username::AbstractString)
    length(get(acdata, username, :session_ids))
end


"Set password for username."
function set_password!(acdata::LoggedDict, username::AbstractString, password::AbstractString)
    if haskey(acdata, username)
	set!(acdata, username, :password, StoredPassword(password))
    else
	LoggedDicts.log(acdata, "ERROR. Cannot set_password because username $username does not exist.")
    end
end


"""
Fetches salt and hashed_password for username from acdata.
If username has no salt or hashed password, returns empty salt and hashed_password (UInt8[], UInt8[]).
"""
function get_salt_hashedpwd(acdata::LoggedDict, username::AbstractString)
    salt, hashed_pwd = UInt8[], UInt8[]
    acdata = config[:acdata]
    if haskey(acdata, username, :password)
	sp         = get(acdata, username, :password)
	salt       = sp.salt
	hashed_pwd = sp.hashed_password
    end
    salt, hashed_pwd
end


function add_roles!(acdata::LoggedDict, username::AbstractString, roles...)
    for role in roles
	push!(s, acdata, username, :roles, role)
    end
end


function remove_roles!(acdata::LoggedDict, username::AbstractString, roles...)
    for role in roles
	pop!(acdata, username, :roles, role)
    end
end


function has_role(acdata::LoggedDict, username::AbstractString, role::AbstractString)
    roles = get(acdata, username, :roles)
    in(role, roles)
end


function get_role(acdata::LoggedDict, username::AbstractString)
    result = ""
    roles  = get(acdata, username, :roles)
    for role in roles
	result = role
	break
    end
    result
end


# EOF
