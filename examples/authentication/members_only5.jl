using HttpServer
using SecureSessions
using AccessControl

include("acdata_members_only.jl")        # User-defined, app-specific access control data (acdata) and access functions
include("handlers_members_only5.jl")

# Generate cert and key for https if they do not already exist
include("generate_cert_and_key.jl")
generate_cert_and_key(@__FILE__)

# Globals
paths                  = Dict{ASCIIString, Function}()    # resource => handler
paths["/home"]         = home_with_login_form!
paths["/members_only"] = members_only!

function app(req::Request)
    res  = Response()
    rsrc = req.resource
    if haskey(paths, rsrc)
        paths[rsrc](req, res)
    elseif rsrc == "/login"
        login!(req, res, acdata, "/members_only")
    elseif rsrc == "/logout"
        logout!(req, res, "/home")
    elseif rsrc == "/reset_password"
        reset_password!(req, res)
    elseif rsrc == "/user_reset_password"
        user_reset_password!(req, res, acdata, "/members_only")
    else
        notfound!(res)
    end
    res
end

server = Server((req, res) -> app(req))
cert   = MbedTLS.crt_parse_file(rel(@__FILE__, "keys/server.crt"))
key    = MbedTLS.parse_keyfile(rel(@__FILE__, "keys/server.key"))
run(server, port = 8000, ssl = (cert, key))