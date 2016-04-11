# Sessions

## Introduction
A session is a conversation between the server and a client. More formally, a session is a sequence of request-response cycles in which the server knows (or thinks it knows) the identity of the client, and therefore can tailor its responses to the client. Sessions are central to access control because they facilitate the two key capabilities of access control:

1. Establishing the client's identity, for example via login with a username and password.
2. Granting/denying the client access to the requested resource according to the application's permissions settings (more on this later).

A session object is simply a Dict with the form: `Dict("id" => session_id, ...)`. That is, the "id" entry is required.

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

__NOTE__: In these docs we run all examples under HTTPS rather than HTTP. This security measure prevents attackers from reading our requests and responses directly off the wire. To do so we call `generate_key_cert` prior to running the server.

## The Basic API

```julia
#=
  Config
    - securecookies::Bool   If true, use secure cookies instead of plain-text cookies
    - max_n_sessions::Int   Max number of simultaneous sessions per user
    - timeout::Int          Number of seconds between requests that results in a session timeout
=#
session_config = Dict("securecookies" => true, "max_n_sessions" => 1, "timeout" => 600)


########################
### Client-side sessions

session = create_session()           # Return Dict("id" => session_id)
session = read_session(req, "id")    # Read the session from the request's "id" cookie
write_session(res, "id", session)    # Write the session object to the response's "id" cookie
delete_session!(res, "id")           # Delete session from response


########################
### Server-side sessions

session_id = create_session(con, res, "id")    # Init "id" => session_id on the database and set the "id" cookie to session_id
session_id = read_sessionid(req, "id")         # Read the session_id from the "id" cookie
get(con, keys...)                              # Read the value located at the path defined by keys...
set(con, keys..., value)                       # Set the value located at the path defined by keys...
delete_session!(con, res, "id")                # Delete session from database and the "id" cookie from the response
```

## Example: Display last visit.
This example displays the timestamp of the requestor's last visit. Run it and visit `https://0.0.0.0:8000/home`. Reload the page (Ctrl-r) to see it update.

### Version: client-side sessions
```julia
using AccessControl

# Handler
function home!(req, res)
    session = read_session(req, "id")
    if session == ""                             # "id" cookie does not exist...session hasn't started...start a new session.
	session  = create_session()
        res.data = "This is your first visit."
    else
        last_visit = session["lastvisit"]
        res.data   = "Welcome back. Your last visit was at $last_visit."
    end
    session["last_visit"] = string(now())
    write_session(res, "id", session)
end

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

generate_key_cert(@__FILE__)     # Generates keys/server.key and keys/server.crt if they don't already exist
server = Server((req, res) -> app(req))
cert   = MbedTLS.crt_parse_file(rel(@__FILE__, "keys/server.crt"))
key    = MbedTLS.parse_keyfile(rel(@__FILE__, "keys/server.key"))
run(server, port = 8000, ssl = (cert, key))
```

### Version: server-side sessions with LoggedDict as database
```julia
using AccessControl
using LoggedDicts

# Database
sessions = LoggedDict("sessions", "sessions.log"; logging = false)

# Handler
function home!(req, res)
    session_id = read_sessionid(req, "id")
    if session_id == ""                             # "id" cookie does not exist...session hasn't started...start a new session.
	session_id = create_session(sessions, res, "id")
        res.data   = "This is your first visit."
    else
        last_visit = get(sessions, session_id, "lastvisit")
        res.data   = "Welcome back. Your last visit was at $last_visit."
    end
    set!(sessions, session_id, "lastvisit", string(now()))
end

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

generate_key_cert(@__FILE__)     # Generates keys/server.key and keys/server.crt if they don't already exist
server = Server((req, res) -> app(req))
cert   = MbedTLS.crt_parse_file(rel(@__FILE__, "keys/server.crt"))
key    = MbedTLS.parse_keyfile(rel(@__FILE__, "keys/server.key"))
run(server, port = 8000, ssl = (cert, key))
```

### Version: server-side sessions with Redis as database
```julia
using AccessControl
using Redis
using ConnectionPools

cp = ConnectionPool(RedisConnection(), 1, 10, 10, 500, 10)    # Pool of connections to the Redis database

# Handler
function home!(req, res)
    conn = get_connection!(cp)                      # Get a connection to Redis database from the connection pool

    session_id = read_sessionid(req, "id")
    if session_id == ""                             # "id" cookie does not exist...session hasn't started...start a new session.
        session_id = create_session(conn, res, "id")
        res.data   = "This is your first visit."
    else
        last_visit = get(conn, session_id, "lastvisit")
        res.data   = "Welcome back. Your last visit was at $last_visit."
    end
    set!(conn, session_id, "lastvisit", string(now()))

    free!(cp, conn)                                 # Release the connection back to the connection pool
end


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

generate_key_cert(@__FILE__)     # Generates keys/server.key and keys/server.crt if they don't already exist
server = Server((req, res) -> app(req))
cert   = MbedTLS.crt_parse_file(rel(@__FILE__, "keys/server.crt"))
key    = MbedTLS.parse_keyfile(rel(@__FILE__, "keys/server.key"))
run(server, port = 8000, ssl = (cert, key))
```

## Todo
1. Rate limiting. Limit the number of requests that a user can make per minute. This is aimed at preventing denial-of-service attacks.
    - rate_limit:       Max number of requests per minute for the given session. Defaults to 100.
    - lockout_duration: Duration (in seconds) of lockout after rate_limit has been reached. Defaults to 1800 (30 mins).
