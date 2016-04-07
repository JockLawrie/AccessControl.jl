#Authentication 

Consider the following app:
```julia
using HttpServer

# Handlers
function home!(req, res)
    res.data = "This is the home page. Anyone can visit here."
end

function members_only!(req, res)
    res.data = "Welcome! This page displays information for members only."
end

function notfound!(res)
    res.status = 404
    res.data   = "Requested resource not found"
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

server = Server((req, res) -> app(req))
run(server, 8000)
```

As it stands, the app allows anyone to see the information that is intended for members only. Lets require users to login to access the restricted information. We will alter the app as follows:
- Run the app under HTTPS, not just HTTP (otherwise the username and password can be intercepted and read by an attacker).
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
using LoggedDicts    # Data store for access control data (users, login credentials, permissions)

# Generate certificate and key for https
rel(filename::AbstractString, p::AbstractString) = joinpath(dirname(filename), p)
if !isfile("keys/server.crt")
    @unix_only begin
	run(`mkdir -p $(rel(filename, "keys"))`)
	run(`openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $(rel(filename, "keys/server.key")) -out $(rel(filename, "keys/server.crt"))`)
    end
end

# Configure access control
acdata          = LoggedDict("acdata", "acdata.log")    # Init access control data
login_config    = Dict("max_attempts" => 5, "lockout_duration" => 1800, "success_redirect" => "/members_only", "fail_msg" => "Username and/or password incorrect")
logout_config   = Dict("redirect" => "/home")
pwdreset_config = Dict("success_redirect" => "/members_only")
AccessControl.configure(acdata, login_config, logout_config, pwdreset_config)

# Add users to acdata: INSECURE - see [Admin Access](AdminAccess.md) for the secure way to do this
AccessControl.create_user!(acdata, "Alice", "pwd_alice")
AccessControl.create_user!(acdata, "Bob",   "pwd_bob")

# Handlers
function home!(req, res)
    res.data = "This is the home page. Anyone can visit here."
end

function members_only!(req, res)
    username = get_session_cookie_data(req, "sessionid")                                # Get username from sessionid cookie if it exists
    is_not_logged_in(username) && notfound!(res)                                        # Check whether user has been authenticated
    res.data = "Welcome $username! This page displays information for members only."    # Note the username in the output
end

# App
function app(req::Request)
    res = Response()
    if rsrc == "/home"
        home!(req, res)
    elseif rsrc == "/members_only"
        members_only!(req, res)
    elseif haskey(acpaths, rsrc)
        acpaths[rsrc](req, res)
    else
        notfound!(res)
    end
    res
end

server = Server((req, res) -> app(req))
cert   = MbedTLS.crt_parse_file(rel(@__FILE__, "keys/server.crt"))
key    = MbedTLS.parse_keyfile(rel(@__FILE__, "keys/server.key"))
run(server, port = 8000, ssl = (cert, key))
```

### Notes
1. The password reset functionality can be omitted by setting `pwdreset_config = nothing`, or by calling `AccessControl.configure(acdata, login_config, logout_config)`.
2. The authentication check could be moved out of the `members_only!` handler. In this example it makes little difference, but this approach will suit some apps and not others.
3. The `notfound!` handler is included in `AccessControl`.
