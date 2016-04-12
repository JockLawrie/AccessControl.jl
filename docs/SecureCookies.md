# Secure Cookies

## Functionality
- Encrypted, tamper-proof cookies; used primarily for stateless secure sessions.

## API
```julia
using HttpCommon

# Create a secure cookie called "id" (use a generic name) and include it in the response.
# data is user-supplied, encrypted and included as part of the cookie value.
data = "John Smith"
res  = Response()
set_securecookie!(res, "id", data)

# Extract and decrypt data from the "id" cookie in the request.
# This is the same user-supplied data included during the cookie's construction.
get_securecookie_data(req, "id")
```

## Security Protocol
Each session cookie is created as follows:

- const_key, const_iv     = global constants, output from a cryptographically secure random number generator (used to encrypt session-specific secret keys)
- timestamp               = milliseconds since epoch, represented as a string
- session_key, session_iv = output from a cryptographic random number generator, unique for each session
- encrypted_session_key   = AES CBC encrypt(const_key, const_iv, session_key)
- data blob               = AES CBC encrypt(session_key, session_iv, arbitrary data)
- hmac signature          = HMAC(session_key, timestamp * data_blob)
- unencoded cookie_value  = session_iv * encrypted_session_key * hmac signature * timestamp * data blob
- cookie_value            = base64encode(unencoded cookie value)...the encoding is for transport in an http header.


## TODO:

- Ensure that cookie attributes are being used correctly
- Compress data before encrypting?

