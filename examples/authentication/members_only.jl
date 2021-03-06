using HttpServer
using AccessControl
using EscapeString    # For escaping the user's name before displaying to the user
using LoggedDicts     # Data store for sessions as well as access control data (users, login credentials, permissions)

# Server-side sessions stored in a LoggedDict
sessions = LoggedDict("sessions", "sessions.log", true)

# Configure access control
acdata          = LoggedDict("acdata", "acdata.log")    # Initialize access control data
session_config  = Dict(:datastore => sessions)
login_config    = Dict(:success_redirect => "/members_only")
logout_config   = Dict(:redirect => "/home")
pwdreset_config = Dict(:success_redirect => "/members_only")
AccessControl.update_config!(acdata, session = session_config, login = login_config, logout = logout_config, pwdreset = pwdreset_config)

# Add users to acdata.
# INSECURE!!! Because usernames and passwords are visible in plain text. See Admin Access for the secure way to do this
AccessControl.create_user!("Alice", "pwd_alice")
AccessControl.create_user!("Bob",   "pwd_bob")

# Handlers
function home!(req, res)
    res.data = "This is the home page. Anyone can visit here.
                <br>
                <br>
                $(login_form())"
end

function members_only!(req, res)
    is_not_logged_in(req) && (notfound!(res); return)        # Check whether user has been authenticated
    session_id = read_sessionid(req)
    username   = session_get(session_id, "username")
    username   = escapestring(username, :html_text)
    res.data   = "Welcome $(username)! This page displays information for members only.
                  <br>
                  $(logout_pwdreset_links())"
end

# App
function app(req::Request)
    res  = Response()
    rsrc = req.resource
    if rsrc == "/home"
        home!(req, res)
    elseif rsrc == "/members_only"
        members_only!(req, res)
    elseif haskey(acpaths, rsrc)        # Note this new clause in the if statement for handling access control
        acpaths[rsrc](req, res)
    else
        notfound!(res)
    end
    res
end


# Run the app under HTTPS rather than HTTP
rel(filename::AbstractString, p::AbstractString) = joinpath(dirname(filename), p)
if !isfile("keys/server.crt")
    @unix_only begin
	run(`mkdir -p $(rel(filename, "keys"))`)
	run(`openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $(rel(filename, "keys/server.key")) -out $(rel(filename, "keys/server.crt"))`)
    end
end

server = Server((req, res) -> app(req))
cert   = MbedTLS.crt_parse_file(rel(@__FILE__, "keys/server.crt"))
key    = MbedTLS.parse_keyfile(rel(@__FILE__, "keys/server.key"))
run(server, port = 8000, ssl = (cert, key))
