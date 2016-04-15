# Authorization

## Role-based access control

Having established a user's identity (authentication), we then grant or deny access to the requested resource based on the identity (authorization). There are several ways to do this, including:

1. Define a table that maps users to the set of resources that they can access.
2. Define a table that maps user types (roles) to the set of resources that they can access.
3. Define access rules within the resource handler, based on either individual users or roles.


 _AccessControl.jl_ uses option 3, which is _role-based access control_. Each user is assigned a role and access to a requested resource is granted or denied according to the role. Defining access rules for roles is easier than doing so for individuals because, typically, there are fewer roles than users and thus fewer rules to keep track of.

Of course, if all users have access to the same resources you can simply omit explicit authorization from your application. As we've seen in earlier examples, access can be granted to everyone, or only to users who are logged in.

To illustrate, we extend the members-only example to show different content to different members. Specifically, members can be gold or silver, and membership type is defined as a user role.
```julia
using HttpServer
using AccessControl
using EscapeString    # For escaping the user's name before displaying to the user
using LoggedDicts     # Data store for sessions as well as access control data (users, login credentials, permissions)

# Server-side sessions stored in a LoggedDict
sessions = LoggedDict("sessions", "sessions.log", true)

# Configure access control
function member_redirect(username::AbstractString)              # Function that defines a redirect location
    role = AccessControl.get_role(username)
    "/members/$(role)"
end
acdata          = LoggedDict("acdata", "acdata.log")            # Initialize access control data
session_config  = Dict(:datastore => sessions)
login_config    = Dict(:success_redirect => member_redirect)    # Use member_redirect(username) after login
logout_config   = Dict(:redirect => "/home")
pwdreset_config = Dict(:success_redirect => member_redirect)
AccessControl.update_config!(acdata, session = session_config, login = login_config, logout = logout_config, pwdreset = pwdreset_config)

# Add users to acdata.
# INSECURE!!! Because usernames and passwords are visible in plain text. See Admin Access for the secure way to do this.
AccessControl.create_user!("Alice", "pwd_alice", Set(["gold"]))
AccessControl.create_user!("Bob",   "pwd_bob",   Set(["silver"]))

# Handlers
function home!(req, res)
    res.data = "This is the home page. Anyone can visit here.
                <br>
                <br>
                $(login_form())"
end

function members_gold!(req, res)
    !has_role(req, "gold") && (notfound!(res); return)        # Check whether user is logged in and has the "gold" role
    session_id = read_sessionid(req)
    username   = session_get(session_id, "username")
    username   = escapestring(username, :html_text)
    res.data   = "Welcome $(username)! This page displays information for GOLD members only.
                  <br>
                  $(logout_pwdreset_links())"
end

function members_silver!(req, res)
    !has_role(req, "silver") && (notfound!(res); return)        # Check whether user is logged in and has the "silver" role
    session_id = read_sessionid(req)
    username   = session_get(session_id, "username")
    username   = escapestring(username, :html_text)
    res.data   = "Welcome $(username)! This page displays information for SILVER members only.
                  <br>
                  $(logout_pwdreset_links())"
end

# App
function app(req::Request)
    res  = Response()
    rsrc = req.resource
    if rsrc == "/home"
        home!(req, res)
    elseif rsrc == "/members/gold"
        members_gold!(req, res)
    elseif rsrc == "/members/silver"
        members_silver!(req, res)
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
	run(`mkdir -p $(rel(@__FILE__, "keys"))`)
	run(`openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $(rel(@__FILE__, "keys/server.key")) -out $(rel(@__FILE__, "keys/server.crt"))`)
    end
end

server = Server((req, res) -> app(req))
cert   = MbedTLS.crt_parse_file(rel(@__FILE__, "keys/server.crt"))
key    = MbedTLS.parse_keyfile(rel(@__FILE__, "keys/server.key"))
run(server, port = 8000, ssl = (cert, key))
```
