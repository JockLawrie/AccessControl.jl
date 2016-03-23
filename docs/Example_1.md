# Example 1
Consider the following app defined in examples/members_only.jl.
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
Run `julia members_only.jl`, then open your browser and navigate to `http://0.0.0.0:8000/treasure`. You should see _This page displays information for members only._ printed on the screen.

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

include("members_only2_handlers.jl")    # Contains handlers for the app defined below

function app(req::Request)
    res = Response()
    if req.resource == "/home"                                      # Home page requires no login
        res.data = display_home_page()
    elseif req.resource == "/login"                                 # Display login page
        res.data = display_login_page()
    elseif req.resource == "/validate_login_credentials"            # Process username and password
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
            res.data = display_login_page()
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




# TODO
From the command line:
```
julia helloworld.jl passwd security_level
```

- If passwd is missing then the admin database is not accessible from the app.
- If passwd is present but security_level is missing then the database is editable and the data is stored unencrypted.
- If passwd and security_level are present then the database is editable and the data is stored encrypted.
