#Authentication 

To run the following examples: `cd examples/authentication/`.

### Example 1
Consider the following app defined in members_only1.jl.
```julia
using HttpServer

function app(req::Request)
    res = Response()
    if req.resource == "/home"
        res.data = "This is the home page. Anyone can visit here."
    if req.resource == "/members_only"
        res.data = "This page displays information for members only."
    else
        res.status = 404
        res.data   = "Requested resource not found"
    end
    res
end

server = Server((req, res) -> app(req))
run(server, 8000)
```
Run `julia members_only1.jl`, then open your browser and navigate to `http://0.0.0.0:8000/members_only`. You should see _This page displays information for members only._ printed on the screen.


### Example 2
As it stands, the app allows anyone to see the information that is intended for members only. Lets require users to login to access the restricted information. We will alter the app as follows:
- Run the app under HTTPS, not just HTTP (otherwise the username and password can be intercepted and read by an attacker).
- Add a login form to the home page.
- If login is successful, redirect the user to the members-only page; else return _400: Bad Request_.
- Add a logout button to the members-only page.
- If a user who is not logged in tries to access the members-only page, return _404: Not Found_ (this is a security measure: an attacker doesn't know whether the resource exists and is forbidden, or the resource doesn't exist).
- If the user has logged in and requests the members-only page, return the requested resource.
- If the user has logged in and requests a non-existent resource, return _404: Not Found_.
- On logout, redirect the user to the home page.

The resulting app may look like this: (members_only2.jl)
```julia
using HttpServer
using SecureSessions
using JSON

include("generate_cert_and_key.jl")
include("handlers_members_only2.jl")


# Generate cert and key for https if they do not already exist
generate_cert_and_key(@__FILE__)

# Database of stored passwords (which are hashed)
password_store          = Dict{AbstractString, StoredPassword}()    # username => StoredPassword
password_store["Alice"] = StoredPassword("pwd_alice")
password_store["Bob"]   = StoredPassword("pwd_bob")

function app(req::Request)
    res = Response()
    if req.resource == "/home"                                      # Home page with login form
        res.data = home_with_login_form()
    elseif req.resource == "/login"                                 # Process login request
	if req.method == "POST"
           qry      = bytestring(req.data)        # query = "username=xxx&password=yyy"
           dct      = parsequerystring(qry)       # Dict("username" => xxx, "password" => yyy)
	   username = dct["username"]
	   password = dct["password"]
	    if login_credentials_are_valid(username, password)      # Successful login: Redirect to members_only page
		res.status = 303
		res.headers["Location"] = "/members_only"
		create_secure_session_cookie(username, res, "sessionid")
	    else                                                    # Unsuccessful login: Return 400: Bad Request
		res.data   = "Bad request"
		res.status = 400
	    end
	else                                                        # Require that login requests are POST requests
	    res.data   = "Bad request"
	    res.status = 400
	end
    else  # User is requesting resource that either requires login or doesn't exist
        username = get_session_cookie_data(req, "sessionid")
        if username == ""                                           # User not logged in: Return 404: Not Found
            res.status = 404
            res.data   = "Requested resource not found."
        else                                                        # User is logged in: Return requested resource
            if req.resource == "/members_only"
                res.data = members_only()
            elseif req.resource == "/logout"                        # User has logged out: Redirect to home page
		res.status = 303
		res.headers["Location"] = "/home"
                setcookie!(res, "sessionid", utf8(""), Dict("Max-Age" => utf8("0")))
            else
                res.status = 404
                res.data   = "Requested resource not found."
            end
        end
    end
    res
end

server = Server((req, res) -> app(req))
cert   = MbedTLS.crt_parse_file(rel(@__FILE__, "keys/server.crt"))
key    = MbedTLS.parse_keyfile(rel(@__FILE__, "keys/server.key"))
run(server, port = 8000, ssl = (cert, key))
```

### Example 3
Despite being a simple app, there's a lot of visual clutter in Example 2. Let's clean this up as follows (members_only3.jl). Note the categorization of resources as either restricted or unrestricted.
```julia
using HttpServer
using SecureSessions

include("handlers_members_only3.jl")


# Database of stored passwords (which are hashed)
password_store = Dict{AbstractString, StoredPassword}()
password_store = StoredPassword("pwd_alice")
password_store = StoredPassword("pwd_bob")

# Resources that do not require authentication
unrestricted_paths               = Dict{ASCIIString, Function}()
unrestricted_paths["/home"]      = home
unrestricted_paths["/login"]     = login
unrestricted_paths["/log_me_in"] = log_me_in

# Resources that require authentication
restricted_paths                 = Dict{ASCIIString, Function}()
resticted_paths["/members_only"] = members_only
resticted_paths["/logout"]       = logout

function app(req::Request)
    res  = Response()
    rsrc = req.resource
    if haskey(unrestricted_paths, rsrc)
        unrestricted_paths[rsrc](req, res)
    elseif haskey(restricted_paths, rsrc)
        username = get_session_cookie_data(req, "sessionid")
        if username == ""
	    notfound!(res)
        else
            restricted_paths[rsrc](req, res)
        end
    else
	notfound!(res)
    end
    res
end

server = Server((req, res) -> app(req))
run(server, 8000)
```


### Example 4
We can clean this up further using macros. This approach also enables us to add an authentication requirement to a resource by adding one line to the corrresponding handler. We will use the same approach for specifying authorization requirements too. Thus all restrictions associated with a resource a specified in one place, namely the handler itself. Our example (members_only4.jl) then becomes:
```julia
using HttpServer
using SecureSessions

include("handlers_members_only4.jl")    # Authentication checks are done in each handler by adding 1 line of code


# Database of stored passwords (which are hashed)
password_store = Dict{AbstractString, StoredPassword}()
password_store = StoredPassword("pwd_alice")
password_store = StoredPassword("pwd_bob")

# Resources
paths                  = Dict{ASCIIString, Function}()    # resource => handler
paths["/home"]         = home
paths["/members_only"] = members_only
paths["/login"]        = login
paths["/log_me_in"]    = log_me_in
paths["/logout"]       = logout

function app(req::Request)
    res  = Response()
    rsrc = req.resource
    if haskey(paths, rsrc)
        paths[rsrc](req, res)
    else
        notfound!(res)
    end
    res
end

server = Server((req, res) -> app(req))
run(server, 8000)
```

__Note:__ Whether the approach of Example 4 is preferable to that of Example 3 depends on your app. If your app has hundreds of resources that all require the same authentication check, then the approach of Example 3 is probably best. That is, add the check once, prior to entering the handler. If access to different resources requires different checks, then the approach of Example 4 may be preferable.


## Todo
```julia
function is_authenticated(req)
    result   = false
    username = get_session_cookie_data(req, "sessionid")
    if username != ""
	result = true
    end
    result
end

macro check_authentication(req, res)
    return quote
        if !is_authenticated($req)
            notfound!($res)
            return nothing    # Early return
        end
    end
end

function myhandler(req, res)
    @check_authentication(req, res)
    # regular handling code
end
```