# Sessions



A session object is simply a Dict with the form: `Dict("id" => session_id, ...)`. That is, the "id" entry is required.

### Example 1
Create a session, store it, read it back.
```julia
using Sessions

session = Dict("id" => csrng(32), "username" => "John Smith", "expires" => now() + Minute(5))

# Client-side sessions
set_securecookie!(res, "id", session)         # Write the session to the "id" cookie in the response
session = get_securecookie_data(req, "id")    # Read the "id" cookie from the request


# Server-side sessions
write_session(ds, "id", session)    # ds is the data store
session = read_session(ds, "id")


```

### Example 2
Conveniences for managing sessions.
```julia
### Impose limit on login attempts

# On first failed login
session["first_login"] = now()
session["login_attempts"] = 1


XXX
```
