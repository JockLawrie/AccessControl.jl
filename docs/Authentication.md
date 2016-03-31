#Authentication 

### Example 1
Consider the following app defined in examples/members_only1.jl.
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
As it stands, the app allows anyone to see the information that is intended for members only. Lets require users to login to access the restricted information. We might alter the app as follows:
- Run the app under HTTPS, not just HTTP (otherwise the username and password can be intercepted and read by an attacker).
- Add a login page, functionality for processing the username and password, and a handler for logout.
- If a user who is not logged in tries to access the resource, return the login page.
- If the user has logged in and requests the resource, return the resource.
- If the user has logged in and requests a non-existent resource, return _404: Not Found_.

The resulting app may look like this: (see examples/members_only2.jl)
```julia
using HttpServer
using SecureSessions

include("handlers_members_only2.jl")

function app(req::Request)
    res = Response()
    if req.resource == "/home"                     # Home page requires no login
        res.data = display_home_page()
    elseif req.resource == "/login"                # Display login page
        res.data = display_login_page()
    elseif req.resource == "/log_me_in"            # Process username and password
        credentials_are_valid = validate_login_credentials(req)
        if credentials_are_valid
            res.data = true
            create_secure_session_cookie(res, "sessionid", username)
        else
            res.data = false
        end
    else
        username = get_session_cookie_data(req, "sessionid")
        if username == ""                                           # User not logged in: Display login page
            res.status = 404
            res.data   = "Requested resource not found."
        else                                                        # User is logged in: Return requested resource
            if req.resource == "/members_only"
                res.data = "This page displays information for members only."
            elseif req.resource == "/logout"
                res.data = display_home_page()
                set_cookie!(res, "sessionid", utf8(""), Dict("Max-Age" => utf8("0")))
            else
                res.status = 404
                res.data   = "Requested resource not found."
            end
        end
    end
    res
end

server = Server((req, res) -> app(req))
run(server, 8000)
```


### Example 3
Despite being a simple app, there's a lot of visual clutter in Example 2. Let's clean this up as follows (see examples/members_only3.jl).
```julia
using HttpServer
using SecureSessions

include("handlers_members_only3.jl")

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
We can clean this up further using macros. This approach also enables us to add an authentication requirement to a resource by adding one line to the corrresponding handler. We will use the same approach for specifying authorization requirements too. Thus all restrictions associated with a resource a specified in one place, namely the handler itself. Our example (examples/members_only4.jl) then becomes:
```julia
using HttpServer
using SecureSessions

include("handlers_members_only4.jl")    # Authentication checks are done in each handler by adding 1 line of code

paths                  = Dict{ASCIIString, Function}()
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
