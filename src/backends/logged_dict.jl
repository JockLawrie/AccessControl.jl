#=
    Contents: Function that generates getters/setters for cfg["acdata"] of typew LoggedDict

    Notes:
    1. The scheme for acdata::LoggedDict is: username => Dict("password" => password, "roles" => Set{AbstractString}).
=#


using LoggedDicts


function create_user!(username::AbstractString, password::AbstractString, roles = Set{AbstractString}(), session_ids = Set{AbstractString}())
    acdata = config[:acdata]
    set!(acdata,  username, Dict{Symbol, Any}())    # username => Dict{Symbol, Any}
    set_password!(acdata, username, password)
    set!(acdata, username, :roles, roles)
    set!(acdata, username, :session_ids, session_ids)
end


function delete_user!(username::AbstractString)
    acdata = config[:acdata]
    if haskey(acdata, username)
	delete!(acdata, username)
    end
end


"Set password for username."
function set_password!(acdata::LoggedDict, username::AbstractString, password::AbstractString)
    if haskey(acdata, username)
	set!(acdata, username, :password, StoredPassword(password))
    else
	LoggedDicts.log(acdata, "ERROR. Cannot set_password because username $username does not exist.")
    end
end

set_password!(username::AbstractString, password::AbstractString) = set_password!(config[:acdata], username, password)


"""
Fetches salt and hashed_password for username from acdata.
If username has no salt or hashed password, returns empty salt and hashed_password (UInt8[], UInt8[]).
"""
function get_salt_hashedpwd(username::AbstractString)
    salt, hashed_pwd = UInt8[], UInt8[]
    acdata = config[:acdata]
    if haskey(acdata, username, :password)
	sp         = get(acdata, username, :password)
	salt       = sp.salt
	hashed_pwd = sp.hashed_password
    end
    salt, hashed_pwd
end


# EOF
