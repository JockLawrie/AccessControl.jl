using AccessControl
using Requests
using Base.Test


# Set up tiered_members app
include("test_tiered_members.jl")    # Defines and runs app on port 8000
sleep(1.0)
client_tls_conf = Requests.TLS_VERIFY
MbedTLS.ca_chain!(client_tls_conf, cert)


# Try to access resource without being logged in.
res = Requests.get("https://0.0.0.0:8000/members/gold", tls_conf = Requests.TLS_NOVERIFY)
@test res.status == 404    # notfound!

# Try logging in with invalid credentials


# Try logging in with valid credentials but using a GET request


# Log in with valid credentials and a POST request
