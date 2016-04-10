# SecureCookies

[![Build Status](https://travis-ci.org/JockLawrie/SecureCookies.jl.svg?branch=master)](https://travis-ci.org/JockLawrie/SecureCookies.jl)
[![Coverage Status](http://codecov.io/github/JockLawrie/SecureCookies.jl/coverage.svg?branch=master)](http://codecov.io/github/JockLawrie/SecureCookies.jl?branch=master)


## WARNING
**The security of this implementation has not been reviewed by a security professional. Use at your own risk.**


## Functionality
SecureCookies provides encrypted, tamper-proof cookies; used primarily for stateless secure sessions.


## Security Protocols
For the current status of the security protocols used see [this doc](https://github.com/JockLawrie/SecureCookies.jl/blob/master/docs/security_protocols.md).


## Usage
The API is detailed below.

Basic examples are in test/runtests.jl.

[This repo](https://bitbucket.org/jocklawrie/skeleton-webapp.jl) contains example web applications:
- Example 5 demonstrates secure cookies.
- Example 6 uses password hashing for login as well as secure cookies.

See ``docs/outline`` for a description of these examples.

## API
```julia
Pkg.add("SecureCookies")
using SecureCookies
using HttpCommon

# Create a secure cookie called "id" (use a generic name) and include it in the response.
# data is user-supplied, encrypted and included as part of the cookie value.
data = "John Smith"
res  = Response()
set_securecookie!(res, "id", data)

# Extract and decrypt data from the "id" cookie in the request.
# This is the same user-supplied data included during the cookie's construction.
get_securecookie_data(req, "id")
```
