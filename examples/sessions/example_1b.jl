#=
    Contents: Example 1b: Display last visit with LoggedDict as database.
=#
using HttpServer
using AccessControl

# Example 1b: LoggedDict as data store for sessions
using LoggedDicts
sessions = LoggedDict("sessions", "sessions.log", true)    # Logging turned off
AccessControl.update_config!(session = Dict(:datastore => sessions))

#=
# Example 1c: Redis as data store for sessions
using Redis
using ConnectionPools
cp  = ConnectionPool(RedisConnection(), 10, 10, 500, 10)    # Pool of connections to the Redis database
AccessControl.update_config!(session = Dict(:datastore => cp))
=#

# Handler
function home!(req, res)
    session_id = read_sessionid(req)
    if session_id == ""                             # "id" cookie does not exist...session hasn't started...start a new session.
        session_id = session_create!(res, "")
        res.data   = "This is your first visit."
    else
        last_visit = session_get(session_id, :lastvisit)
        res.data   = "Welcome back. Your last visit was at $last_visit."
        session_set!(session_id, :lastvisit, string(now()))
    end
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
