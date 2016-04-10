# Sessions

# Config
#max_n_sessions: Max number of simultaneous sessions per user
#limit_rate: Number of requests per minute for the given session
session_config = Dict("max_n_sessions" => 1, limit_rate => 100)

# Create "id" cookie in res and return session::Dict with "id" set.
session = create_session(res, "id", secure = true)    # secure=true means use secure cookie

# set session key-value pairs here

# Write session to data store
# For client-side sessions, the data store is the secure cookie
write_session(res::Response, "id", session)    # For client-side sessions
write_session(data_store, session)             # For server-side sessions

# Read session from data store
session = read_session(req, "id")                 # For client-side sessions
session = read_session(data_store, session_id)    # For server-side sessions

# Delete session
delete_session!(res, "id")                # For client-side sessions
delete_session!(res, "id", data_store)    # For server-side sessions




################
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
