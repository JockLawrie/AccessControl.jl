# Sessions

## Introduction
A session is a conversation between the server and a client. More formally, a session is a sequence of request-response cycles in which the server knows (or thinks it knows) the identity of the client, and therefore can tailor its responses to the client. Sessions are central to access control because they facilitate the two key capabilities of access control:

1. Establishing the client's identity, for example via login with a username and password.
2. Granting/denying the client access to the requested resource according to the application's permissions settings (more on this later).

Conceptually, a session object is simply a Dict with the form: `Dict("id" => session_id, ...)`. That is, the "id" entry is required. The actual implementation differs depending on where the session is stored...

## Client-side sessions vs server-side sessions
A session is a client-side session if it is stored in a cookie in the response. Typically the cookie has the form `id=session`, where `id` is the cookie name that the server recognizes as the session cookie name, and `session` is a string repsentation of a session object, usually encrypted. When a request comes in, the server extracts the session object from the session cookie.

A session is a server-side session if it is stored on the server or a database server. Server-side sessions also need to maintain a cookie in the response so that it can identify the client from the request. The cookie has the form `id=session_id`, where the `session_id` is a long identifier generated from a cryptographically secure random number generator. When a request comes in, the server extracts the session ID from the session cookie and fetches any required session information from the database that stores the session object.

It may seem that client-side sessions are less complicated. But there is a trade-off when deciding whether to use client-side or server-side sessions.

Advantages of client-side sessions

- Simpler architecture. All session information is in one place.
- No need to keep track of session information, just read it off the cookie when it arrives.

Advantages of server-side sessions

- More secure.
    - No session information other than the session ID leaves the server, so it can't be read, updated or deleted outside the server environment. An attacker would need to breach the server environment to access session information.
    - Sessions can be revoked. If access privileges change, the session can be terminated. This is not always possible with client-side sessions, particularly when an application is under attack.
- Can store more than 4kb of data. Client-side sessions can store a maximum of 4096 bytes of data.

It is often argued that client-side cookies scale better than server-side cookies. But these days this argument is weak. If your application has a million users and sessions can fit into a cookie, then that would take 4096M bytes, or 4MB, of storage. Moreover, with such a popular application, the problem of automatic failover should be solved as part of the application's architecture. The maintenance of highly available sessions can piggy back that effort.

## HTTPS

__NOTE__: In these docs we run all examples under HTTPS rather than HTTP. This security measure prevents attackers from reading our requests and responses directly off the wire.

## API

### Config
Access control configuration is stored in `AccessControl.config`, which is a `Dict`. Both client-side and server-side sessions have the following default session configuration in common, which can be modified as desired:
```julia
config[:session] = Dict(:datastore => :cookie,    # One of: :cookie::Symbol, ld::LoggedDict, cp::ConnectionPool
                        :cookiename => "id",      # Store the session (client-side) or session ID (server-side) in the "id" cookie
                        :id_length => 32,         # Length of the session ID in bytes
                        :max_n_sessions => 1,     # Max number of simultaneous sessions for a given user
                        :timeout => 600)          # Max number of seconds between requests in the same session

config[:securecookie]   = Dict{Symbol, Any}(:cookie_max_age => 10 * 60 * 1000,    # Duration of a session's validity in milliseconds
                                            :key_length     => 32,                # Key length for AES 256-bit cipher in CBC mode
                                            :block_size     => 16,                # IV  length for AES 256-bit cipher in CBC mode
                                            :cookie_attr    => Dict("Max-Age" => "600", "Secure" => "", "HttpOnly" => ""))
```

To change config settings, call `AccessControl.update_config!(x = y)`, where:
- `x` is one of the following keywords: `acdata`, `session`, `securecookie`, `login`, `logout`, `pwdreset`.
- `y` contains the corresponding _changes_.

__Note:__ Only config elements supplied as arguments to `update_config!` are updated. Those that are not supplied remain unchanged. For example, suppose we wish to change the cookie name to "session_id". Then we needn't supply the entire `config[:session]` dict as an argument. Instead we can just call:

```julia
AccessControl.update_config!(session = Dict(:cookiename => "session_id"))
```

### Client-Side Sessions
Client-side sessions are `Dict`s stored in a cookie. They have the following create, read, write and delete functions. Updating sessions occurs in the application code using standard Julia syntax for modifying `Dict`s.
```julia
### Client-side sessions
session = session_create!(username)    # Returns: Dict("username" => username, "lastvisit" => string(now()))
session = session_read(req)            # Read the session object from the request's session cookie
session_write!(res, session)           # Write the session to the "id" cookie
session_delete!(res)                   # Set the response's "id" cookie to an invalid state
```

### Server-Side Sessions
Server-side sessions store a session ID in a cookie AND a session object on the database. The implementation of the session object depends on the database used. This package provides the following CRUD (create/read/update/delete) functions. Currently `LoggedDict`s and Redis are the only supported databases.
```julia
### Server-side sessions
session_id = session_create!(res, username)    # Init session_id => session on the database and set the "id" cookie to session_id
session_id = read_sessionid(req)               # Read the session_id from the "id" cookie
session_get(session_id, keys...)               # Read the value located at the path defined by keys...
session_set!(sesion_id, keys..., value)        # Set the value located at the path defined by keys...
session_delete!(res, session_id)               # Delete session from database and set the response's "id" cookie to an invalid state
```


## Example: Display last visit
This example displays the timestamp of the requestor's last visit. Run it and visit `https://0.0.0.0:8000/home`. Reload the page (Ctrl-r) to see it update.

We show 3 versions: client-side sessions, server-side sessions with a `LoggedDict` as the database, and server-side sessions with Redis as the database. The 3 versions have the following code in common:
```julia
### INSERT HANDLER AND ANY OTHER DEPENDENCIES HERE

# App
function app(req::Request)
    res = Response()
    if req.resource == "/home"
        home!(req, res)
    else
        notfound!(res)
    end
    res
end

### Run the app under HTTPS
# Generate keys/server.key and keys/server.crt if they don't already exist
rel(filename::AbstractString, p::AbstractString) = joinpath(dirname(filename), p)
if !isfile("keys/server.crt")
    @unix_only begin
	run(`mkdir -p $(rel(@__FILE__, "keys"))`)
	run(`openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $(rel(@__FILE__, "keys/server.key")) -out $(rel(@__FILE__, "keys/server.crt"))`)
    end
end

# Define and run the server
server = Server((req, res) -> app(req))
cert   = MbedTLS.crt_parse_file(rel(@__FILE__, "keys/server.crt"))
key    = MbedTLS.parse_keyfile(rel(@__FILE__, "keys/server.key"))
run(server, port = 8000, ssl = (cert, key))
```

### Example: Client-side sessions
```julia
using HttpServer
using AccessControl

# Handler
function home!(req, res)
    session = session_read(req)
    if session == ""                             # "id" cookie does not exist...session hasn't started...start a new session.
        session  = session_create!("")
        res.data = "This is your first visit."
        session["lastvisit"] = string(now())
        session_write!(res, session)
    else
        last_visit = session["lastvisit"]
        res.data   = "Welcome back. Your last visit was at $last_visit."
        session["lastvisit"] = string(now())
        session_write!(res, session)
    end
end
```

### Example: Server-side sessions
__A note on storing session data on the server__

Suppose we want to store `Dict(k1 => Dict(k2 => Dict(k3 => v)))` in a session. If the session is stored in a `LoggedDict` we can use the syntax `set!(ld, k1, k2, k3, v)`. This uses the concept of a _key path_, which is the ordered sequence of keys `k1, k2, k3`.

What if we want to store this session data in Redis, which can't nest data structures like this? We use the key path idea again: we flatten the sequence of keys and store `k1:k2:k3 => v`. Thus the key path concept allows a common API for different data stores.

To store sessions in Redis we use the following schema:

- "sessions" => Set(session_id1, ...),      set of current valid session_ids.
- "session:$(session_id):$(keypath)" => v,  key-value pairs for session_id.
- "session:keypaths" => Set(keypath1, ...), exploits the fact that session fields come from a common app-specific set.
```julia
using HttpServer
using AccessControl

# Example 1b: LoggedDict as data store for sessions
using LoggedDicts
sessions = LoggedDict("sessions", "sessions.log", true)                 # Logging turned off
AccessControl.update_config!(session = Dict(:datastore => sessions))    # Updates default config

#=
# Example 1c: Redis as data store for sessions
using Redis
using ConnectionPools
cp  = ConnectionPool(RedisConnection(), 10, 10, 500, 10)                # Pool of connections to the Redis database
AccessControl.update_config!(session = Dict(:datastore => cp))          # Updates default config
=#

# Handler
function home!(req, res)
    session_id = read_sessionid(req)
    if session_id == ""                             # "id" cookie does not exist...session hasn't started...start a new session.
        session_id = session_create!(res, "")
        res.data   = "This is your first visit."
        session_set!(session_id, "lastvisit", string(now()))
    else
        last_visit = session_get(session_id, "lastvisit")
        res.data   = "Welcome back. Your last visit was at $last_visit."
        session_set!(session_id, "lastvisit", string(now()))
    end
end
```
