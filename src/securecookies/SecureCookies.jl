module SecureCookies

using HttpServer
using MbedTLS


export set_securecookie!, get_securecookie_data, invalidate_cookie!


include("utils.jl")
include("secure_cookies.jl")


# Globals
session_timeout = 5 * 60 * 1000        # Duration of a session's validity in milliseconds
key_length      = 32                   # Key length for AES 256-bit cipher in CBC mode
block_size      = 16                   # IV  length for AES 256-bit cipher in CBC mode
const_key       = csrng(key_length)    # Symmetric key for encrypting secret_keys (with 256-bit encryption)
const_iv        = csrng(block_size)    # IV for encrypting secret_keys
timeout_str     = utf8(string(convert(Int64, 0.001 * session_timeout)))    # Session timeout in seconds, represented as a string

default_attributes = Dict("Max-Age" => timeout_str, "Secure" => "", "HttpOnly" => "")


end # module
