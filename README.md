# AccessControl

## Getting started
Access control can be included within an existing app, or it can exist as a stand-alone service that an an existing app can use.

### Include access control within an existing app
Create a file containing your application. In this example we have helloworld.jl.
```julia
using HttpServer
using AccessControl

paths = Dict{ASCIIString, Function}()    # route => handler
paths["/home"] = home

# Handlers
function home(req, res)
    res.data = "Hello World!"
end


# App
function app(req::Request)
    res = Response()
    if haskey(paths, req.resource)
        paths[req.resource](req, res)
    else
        res.status = 404
        res.data   = "Requested resource not found."
    end
    res
end


access_control()
server = Server((req, res) -> app(req))
run(server, 8000)
```

Then from the command line:
```
julia helloworld.jl passwd security_level
```

- If passwd is missing then the admin database is not accessible from the app.
- If passwd is present but security_level is missing then the database is editable and the data is stored unencrypted.
- If passwd and security_level are present then the database is editable and the data is stored encrypted.


### Run access control as a stand-alone service.
