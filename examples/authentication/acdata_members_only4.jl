#=
    Contents: Functions for connecting to app-specific access control data.

    The user must define:
    1. A data store containing access control data,  OR
       a connection to such a data store, OR
       a pool of such connections.
    2. A function get_salt_hashedpwd(username::AbstractString, acdata), where:
       - acdata is the access control data store or connection defined in 1.
       - the function returns salt, hashed_pwd if it exists for username, or UInt8[], UInt8[] otherwise.
=#


# Data store of access control data
acdata          = Dict{AbstractString, StoredPassword}()    # username => StoredPassword
acdata["Alice"] = StoredPassword("pwd_alice")
acdata["Bob"]   = StoredPassword("pwd_bob")


"""
Fetches salt and hashed_password for username from acdata.

If username has no salt or hashed password, returns empty salt and hashed_password (UInt8[], UInt8[]).
"""
function get_salt_hashedpwd(username::AbstractString, acdata)
    salt, hashed_pwd = UInt8[], UInt8[]
    if haskey(acdata, username)
	sp         = acdata[username]
	salt       = sp.salt
	hashed_pwd = sp.hashed_password
    end
    salt, hashed_pwd
end
