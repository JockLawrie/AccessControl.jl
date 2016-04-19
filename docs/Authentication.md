#Authentication 

Consider the following app:
```julia
using HttpServer
using AccessControl    # Contains the notfound! handler

# Handlers
function home!(req, res)
    res.data = "This is the home page. Anyone can visit here."
end

function members_only!(req, res)
    res.data = "Welcome! This page displays information for members only."
end

# App
function app(req::Request)
    res  = Response()
    rsrc = req.resource
    if rsrc == "/home"
        home!(req, res)
    elseif rsrc == "/members_only"
        members_only!(req, res)
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

As it stands, the app allows anyone to see the information that is intended for members only. Lets require users to login to access the restricted information. We will alter the app as follows:
- Add a login form to the home page.
- If login is successful, redirect the user to the members-only page and display member-specific content (in this example, the member's name).
- If login is not successful return a message for the user.
- Add logout and password reset links to the members-only page.
- If a user who is not logged in tries to access the members-only page, return _404: Not Found_ (this is a security measure: an attacker doesn't know whether the resource exists and is forbidden, or the resource doesn't exist).
- If the user has logged in and requests the members-only page, return the requested resource.
- If the user has logged in and requests a non-existent resource, return _404: Not Found_.
- If password reset is successful, redirect the user to the members-only page, otherwise return a message for the user.
- On logout, redirect the user to the home page.

The resulting app looks like this:
```julia
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
```

### Notes
1. The password reset functionality can be omitted by setting `pwdreset_config = nothing`, or by calling `AccessControl.configure(acdata, login_config, logout_config)`.
2. The authentication check could be moved out of the `members_only!` handler. In this example it makes little difference, but the approach will suit some apps and not others.
3. The elements of `config` that concern authentication are:
```julia
config[:login]    = Dict(:max_attempts => 5,           # Max number of allowed login attempts
                         :lockout_duration => 1800,    # Duration (sec) of lockout after max_attempts failed login attempts
			 :success_redirect => "/",     # Redirect location on successful login. Can be a function of the user.
			 :fail_msg => "Username and/or password incorrect.")    # Alert message on failed login attempt

config[:logout]   = Dict(:redirect => "/")         # Redirect location on logout

config[:pwdreset] = Dict(:max_attempts => 5,           # Max number of allowed attempts at password reset
                         :lockout_duration => 1800,    # Duration (sec) of lockout after max_attempts failed attempts
			 :success_redirect => "/",     # Redirect location on successful password reset. Can be a function of the user.
			 :fail_msg => "Password incorrect.")    # Alert message on failed password reset attempt
```
