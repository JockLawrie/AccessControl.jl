# Contents: Functions for creating/handling secure cookies.

################################################################################
# Create secure cookie
#
# The scheme:
#     const_key, const_iv     = global constants, output from a cryptographically secure random number generator
#                               (used to encrypt session-specific secret keys)
#     timestamp               = milliseconds since epoch, represented as a string
#     session_key, session_iv = output from a cryptographic random number generator, unique for each session
#     encrypted_session_key   = AES CBC encrypt(const_key, const_iv, session_key)
#     data blob               = AES CBC encrypt(session_key, session_iv, arbitrary data)
#     hmac signature          = HMAC(session_key, timestamp * data_blob)
#     unencoded cookie_value  = session_iv * encrypted_secret_key * hmac signature * timestamp * data blob
#     cookie_value            = base64encode(unencoded cookie value)
#                               (the encoding is for transport in an http header)
#
################################################################################

"""
Create a secure session cookie for the response.
The cookie value includes the encryption of the supplied data.
The Secure and HttpOnly attributes are set according to global variables.
"""
function set_securecookie!(res::Response, cookie_name::AbstractString, data::AbstractString, attr = config[:securecookie][:cookie_attr])
    cookie_value = create_securecookie_value(data)
    setcookie!(res, cookie_name, utf8(cookie_value), attr)
end


"""
Create the value of the secure session cookie.

Input:  Data (ASCIIString) to be embedded in the encrypted cookie value.
Output: Cookie value (ASCIIString) 

Note: Binary data is base64 encoded for transport in http headers (base64 is more space efficient than hex encoding).
"""
function create_securecookie_value(plaintext::AbstractString)
    key_length, block_size, const_key, const_iv = get_securecookie_config()

    # Encrypt data 
    session_key = csrng(key_length)
    session_iv  = csrng(block_size)
    data_blob   = encrypt(CIPHER_AES, session_key, plaintext, session_iv)    # Encryption is done in CBC mode

    # Compute HMAC signature
    timestamp      = string(get_timestamp())    # Millieconds since epoch
    ts_uint8       = convert(Array{UInt8, 1}, timestamp)
    hmac_signature = digest(MD_SHA256, vcat(ts_uint8, data_blob), session_key)

    # Compute cookie value
    encrypted_session_key = encrypt(CIPHER_AES, const_key, session_key, const_iv)
    cookie_value          = base64encode(vcat(session_iv, encrypted_session_key, hmac_signature, ts_uint8, data_blob))
    cookie_value
end


################################################################################
# Validate secure cookie
################################################################################

# The package validates a secure cookie as follows:
# 1. Decode hmac signature.
# 2. Compute HMAC(secret key, timestamp * data blob) and compare it to hmac signature. Fail if they differ.
# 3. Decode timestamp.
# 4. Verify that the current time in milliseconds since the epoch is not greater than timestamp + session timeout.
#
# If the cookie is valid, the package then:
# 1. Decrypts data blob
# 2. Parses or deserializes data blob as appropriate.


"""
Returns the decrypted cookie data.

Returns "" if the cookie doesn't exist.
"""
function get_securecookie_data(req::Request, cookie_name::AbstractString)
    result = ""
    if haskey(req.headers, "Cookie")
	cookie_value = get_cookie_value(req, cookie_name)
	if cookie_value != ""
	    cookie_is_valid, data_blob, session_key, session_iv = securecookie_is_valid(cookie_value)
	    if cookie_is_valid
		result = decrypt(CIPHER_AES, session_key, data_blob, session_iv)
		result = utf8(result)
	    end
	end
    end
    result
end


"""
Returns the cookie value, which is encrypted.

Returns "" if the cookie doesn't exist.
"""
function get_cookie_value(req::Request, cookie_name::AbstractString)
    cookie_value = ""
    ckie         = req.headers["Cookie"]    # ASCIIString: "name1=value1; name2=value2"
    names_values = split(ckie, ";")         # "name=value"
    for nv in names_values
	r = search(nv, cookie_name)         # first_idx:last_idx
	if length(r) > 0                    # cookie_name is in nv
	    r2           = search(nv, "=")
	    cookie_value = nv[(r2[1] + 1):end]
	    break
	end
    end
    convert(ASCIIString, cookie_value)      # Convert SubString to string for base64 decoding
end


"""
Returns: cookie_is_valid (Bool) and session data.

cookie_is_valid is true if session cookie:
1) Has not expired, and
2) hmac_signature == HMAC(secret key, timestamp * data_blob)
"""
function securecookie_is_valid(cookie_value::AbstractString)
    key_length, block_size, const_key, const_iv = get_securecookie_config()
    cookie_max_age = config[:securecookie][:cookie_max_age]

    # Extract cookie data
    cookie_value   = base64decode(cookie_value)
    session_iv     = cookie_value[1:block_size]
    offset         = block_size
    encrypted_session_key = cookie_value[(offset + 1):(offset + key_length + block_size)]
    session_key    = decrypt(CIPHER_AES, const_key, encrypted_session_key, const_iv)
    offset += key_length + block_size
    hmac_signature = slice(cookie_value, (offset + 1):(offset + key_length))
    offset += key_length
    ts_uint8       = cookie_value[(offset + 1):(offset + 13)]
    timestamp      = parse(Int, utf8(ts_uint8))    # Seconds since epoch
    offset += 13
    data_blob      = cookie_value[(offset + 1):end]

    # Determine conditions
    current_time = get_timestamp()
    expired      = current_time > timestamp + cookie_max_age
    hmac_sig2    = digest(MD_SHA256, vcat(ts_uint8, data_blob), session_key)
    hmac_ok      = hmac_sig2 == hmac_signature

    # Prepare results
    cookie_is_valid = false
    if !expired && hmac_ok
        cookie_is_valid = true
    end
    cookie_is_valid, data_blob, session_key, session_iv
end


"""
Invalidates the cookie with name == cookie_name.
Curently this works by setting:
- Max-Age = 0
- Data    = ""
"""
function invalidate_cookie!(res::Response, cookie_name::AbstractString)
    setcookie!(res, cookie_name, utf8(""), Dict("Max-Age" => utf8("0")))
end


################################################################################
# Utils
################################################################################
"""
Returns: Milliseconds since the epoch.
Takes 13 characters (valid until some time around the year 2287).
"""
function get_timestamp()
    1000 * convert(Int, Dates.datetime2unix(now()))
end


"Inserts derived values for keys: :const_key, :const_iv, :cookie_attr."
function update_securecookie_config!(k::Symbol)
    if k == :key_length    # :key_length has changed >> update :const_key
	key_length = config[:securecookie][:key_length]
	config[:securecookie][:const_key] = csrng(key_length)          # Symmetric key for encrypting secret_keys (with 256-bit encryption)
    elseif k == :block_size
	block_size = config[:securecookie][:block_size]
	config[:securecookie][:const_iv]  = csrng(block_size)          # IV for encrypting secret_keys
    elseif k == :cookie_max_age
	max_age     = config[:securecookie][:cookie_max_age]
	timeout_str = utf8(string(convert(Int64, 0.001 * max_age)))    # Session timeout in seconds, represented as a string
	config[:securecookie][:cookie_attr] = Dict("Max-Age" => timeout_str, "Secure" => "", "HttpOnly" => "")
    end
end


function get_securecookie_config()
    d = config[:securecookie]
    d[:key_length], d[:block_size], d[:const_key], d[:const_iv]
end


# EOF
