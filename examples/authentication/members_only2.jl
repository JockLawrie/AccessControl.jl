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
    if req.resource == "/home"                                      # Home page requires no login
        res.data = home_with_login_form()
    elseif req.resource == "/login"                                 # Process username and password
	if req.method == "POST"
	    up = JSON.parse(bytestring(req.data))                   # Dict("username" => username, "password" => password)
	    if login_credentials_are_valid(up["username"], up["password"])    # Redirect to members_only page
		res.status = 303
		res.headers["Location"] = "/members_only"
		create_secure_session_cookie(up["username"], res, "sessionid")
	    else
		res.data   = "Bad request"
		res.status = 400
	    end
	else
	    res.data   = "Bad request"
	    res.status = 400
	end
    else
        username = get_session_cookie_data(req, "sessionid")
        if username == ""                                           # User not logged in: Return 404
            res.status = 404
            res.data   = "Requested resource not found."
        else                                                        # User is logged in: Return requested resource
            if req.resource == "/members_only"
                res.data = "This page displays information for members only."
            elseif req.resource == "/logout"
		res.status = 303                                    # Redirect to home page
		res.headers["Location"] = "/home"
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
cert   = MbedTLS.crt_parse_file(rel(@__FILE__, "keys/server.crt"))
key    = MbedTLS.parse_keyfile(rel(@__FILE__, "keys/server.key"))
run(server, port = 8000, ssl = (cert, key))
