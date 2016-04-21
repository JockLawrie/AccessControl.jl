using AccessControl
using Requests
using Base.Test


# Set up tiered_members app
include("test_tiered_members.jl")    # Defines and runs app on port 8000
sleep(1.0)
client_tls_conf = Requests.TLS_VERIFY
MbedTLS.ca_chain!(client_tls_conf, cert)


################################################################################
### Logging in

# Try to access resource without being logged in.
res = Requests.get("https://0.0.0.0:8000/members/gold", tls_conf = Requests.TLS_NOVERIFY)
@test res.status == 404    # notfound!

# Try logging in with invalid credentials
postdata = "username=Alice&password=xxx"
res = Requests.post("https://0.0.0.0:8000/login", tls_conf = Requests.TLS_NOVERIFY; data = postdata)
@test res.status == 400   # Bad request
@test bytestring(res.data) == "Username and/or password incorrect."

# Try logging in with valid credentials but using a GET request
postdata = "username=Alice&password=pwd_alice"
res = Requests.get("https://0.0.0.0:8000/login", tls_conf = Requests.TLS_NOVERIFY; data = postdata)
@test res.status == 400   # Bad request

# Log in with valid credentials and a POST request
postdata = "username=Alice&password=pwd_alice"
res      = Requests.post("https://0.0.0.0:8000/login", tls_conf = Requests.TLS_NOVERIFY; data = postdata)
cookie   = res.cookies["id"]
@test res.status == 200


################################################################################
### Role-based access

# Access restricted resource with invalid role
res = Requests.get("https://0.0.0.0:8000/members/silver", tls_conf = Requests.TLS_NOVERIFY; cookies = [cookie])
@test res.status == 404    # notfound!

# Access restricted resource with valid role
res = Requests.get("https://0.0.0.0:8000/members/gold", tls_conf = Requests.TLS_NOVERIFY; cookies = [cookie])
@test res.status == 200


################################################################################
### Password reset

# Get reset_password form with valid login
res = Requests.get("https://0.0.0.0:8000/reset_password", tls_conf = Requests.TLS_NOVERIFY; cookies = [cookie])
@test res.status == 200

# Get reset_password form with invalid login
res = Requests.get("https://0.0.0.0:8000/reset_password", tls_conf = Requests.TLS_NOVERIFY)
@test res.status == 404    # notfound!

# process_pwdreset with invalid login
postdata = "current_pwd=xxx&new_pwd=yyy&new_pwd2=zzz"
res = Requests.post("https://0.0.0.0:8000/process_pwdreset", tls_conf = Requests.TLS_NOVERIFY; data=postdata)
@test res.status == 404    # notfound!

# process_pwdreset with valid login but using a GET request
postdata = "current_pwd=xxx&new_pwd=yyy&new_pwd2=zzz"
res = Requests.get("https://0.0.0.0:8000/process_pwdreset", tls_conf = Requests.TLS_NOVERIFY; cookies = [cookie], data = postdata)
@test res.status == 400    # bad request
@test bytestring(res.data) == "Bad request"

# process_pwdreset with valid login and using a POST request, but with invalid current_pwd
postdata = "current_pwd=xxx&new_pwd=yyy&new_pwd2=yyy"
res = Requests.post("https://0.0.0.0:8000/process_pwdreset", tls_conf = Requests.TLS_NOVERIFY; cookies = [cookie], data = postdata)
@test res.status == 400    # bad request
@test bytestring(res.data) == "Password incorrect."

# process_pwdreset with valid login and using a POST request, but with non-matching new_pwd and new_pwd2
postdata = "current_pwd=pwd_alice&new_pwd=yyy&new_pwd2=zzz"
res = Requests.post("https://0.0.0.0:8000/process_pwdreset", tls_conf = Requests.TLS_NOVERIFY; cookies = [cookie], data = postdata)
@test res.status == 400    # bad request
@test bytestring(res.data) == "Password incorrect."

# process_pwdreset with valid login and using a POST request, and with valid post data
postdata = "current_pwd=pwd_alice&new_pwd=yyy&new_pwd2=yyy"
res = Requests.post("https://0.0.0.0:8000/process_pwdreset", tls_conf = Requests.TLS_NOVERIFY; cookies = [cookie], data = postdata)
@test res.status == 200


################################################################################
### Logout

# Logout without being logged in
res = Requests.get("https://0.0.0.0:8000/logout", tls_conf = Requests.TLS_NOVERIFY)
@test res.status == 404    # notfound!

# Logout while logged in 
res     = Requests.get("https://0.0.0.0:8000/logout", tls_conf = Requests.TLS_NOVERIFY; cookies = [cookie])
cookie2 = res.cookies["id"]
@test res.status == 200
@test cookie2.attrs["Max-Age"] == "0"


################################################################################
### Login with new password (recently reset)

# Try to access resource without being logged in.
res = Requests.get("https://0.0.0.0:8000/members/gold", tls_conf = Requests.TLS_NOVERIFY)
@test res.status == 404    # notfound!

# Try to access resource with an expired login.
res = Requests.get("https://0.0.0.0:8000/members/gold", tls_conf = Requests.TLS_NOVERIFY; cookies = [cookie])
@test res.status == 404    # notfound!

# Log in with the old (invalid) credentials
postdata = "username=Alice&password=pwd_alice"
res      = Requests.post("https://0.0.0.0:8000/login", tls_conf = Requests.TLS_NOVERIFY; data = postdata)
@test res.status == 404    # notfound!

# Log in with the new (valid) credentials
postdata = "username=Alice&password=yyy"
res      = Requests.post("https://0.0.0.0:8000/login", tls_conf = Requests.TLS_NOVERIFY; data = postdata)
@test res.status == 200

# EOF
