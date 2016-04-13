# SecureSessions


## Functionality
- Password hashing; used for login.


## Security Protocols
For the current status of the security protocols used see [this doc](https://github.com/JockLawrie/SecureSessions.jl/blob/master/docs/security_protocols.md).


## Usage
The API is detailed below.

Basic examples are in test/runtests.jl.

[This repo](https://bitbucket.org/jocklawrie/skeleton-webapp.jl) contains example web applications:
- Example 5 demonstrates secure cookies.
- Example 6 uses password hashing for login as well as secure cookies.

See ``docs/outline`` for a description of these examples.

## API
```julia
Pkg.add("SecureSessions")
using SecureSessions

##########################
### Password storage
##########################
password_is_permissible(password)     # Returns true if password adheres to a set of rules defined in the package

# Store password...add salt, then hash, then store in type StoredPassword.
immutable StoredPassword
    salt::Array{UInt8, 1}
    hashed_password::Array{UInt8, 1}
end

# The constructor argument is an AbstractString
# A salt is randomly generated using a cryptographically secure RNG
sp = StoredPassword(password)
password_is_valid(password::AbstractString, sp::StoredPassword)    # Returns true if hash(sp.salt, password) == sp.hashed_password
```
