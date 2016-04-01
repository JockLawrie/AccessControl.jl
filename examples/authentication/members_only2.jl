using HttpServer
using SecureSessions

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
                invalidate_cookie!(res, "sessionid")
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
