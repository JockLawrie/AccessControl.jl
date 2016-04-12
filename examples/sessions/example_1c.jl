#=
    Contents: Example 1c: Display last visit with Redis as database.
=#
using HttpServer
using AccessControl
using Redis
using ConnectionPools

# Database
cp  = ConnectionPool(RedisConnection(), 0, 10, 10, 500, 10)    # Pool of connections to the Redis database
con = get_connection!(cp)
sadd(con, "session:keypaths", "lastvisit")
free!(cp, con)

# Handler
function home!(req, res)
    con        = get_connection!(cp)                           # Get a connection to Redis database from the connection pool
    session_id = read_sessionid(req, "id")
    if session_id == ""                                        # "id" cookie does not exist...session hasn't started...start a new session.
        session_id = create_session(con, res, "id")
        res.data   = "This is your first visit."
    else
	last_visit = get(con, "session:$session_id", "lastvisit")
        res.data   = "Welcome back. Your last visit was at $last_visit."
    end
    set!(con, "session:$session_id", "lastvisit", string(now()))
    free!(cp, con)                                             # Release the connection back to the connection pool
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

