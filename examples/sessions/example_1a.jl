#=
    Contents: Example 1a: Display last visit with client-side sessions.
=#
using HttpServer
using AccessControl

# Handler
function home!(req, res)
    session = session_read(req)
    if session == ""                             # "id" cookie does not exist...session hasn't started...start a new session.
        session  = session_create!("")           # username = ""
        res.data = "This is your first visit."
        session_write!(res, session)
    else
        last_visit = session["lastvisit"]
        res.data   = "Welcome back. Your last visit was at $last_visit."
	session["lastvisit"] = string(now())
        session_write!(res, session)
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
