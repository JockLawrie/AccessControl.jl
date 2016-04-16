module AccessControl

using HttpServer
using MbedTLS
using JSON
using ConnectionPools

import Redis.get, LoggedDicts.set!

export
    acpaths,                                      # Dict(path => handler) for authentication functionality
    session_create!, session_delete!,             # Common session functions
    session_read, session_write!,                 # Client-side sessions
    read_sessionid, session_get, session_set!,    # Server-side sessions
    notfound!, badrequest!, redirect!,            # Generic handlers
    login_form, pwdreset_form, logout_link, logout_pwdreset_links,    # AuthN HTML
    login!, logout!, process_pwdreset!,           # AuthN handlers
    is_logged_in, is_not_logged_in,               # AuthN utils
    has_role                                      # AuthZ utils

### Config - to be updated by the app's call to AccessControl.configure()
config                  = Dict{Symbol, Any}()
config[:admin_password] = nothing
config[:acdata]         = nothing                                   # No default data store for access control data
config[:session]        = Dict(:datastore => :cookie,               # One of: :cookie::Symbol, ld::LoggedDict, cp::ConnectionPool
                               :cookiename => "id", :id_length => 32, :max_n_sessions => 1, :timeout => 600)
config[:login]          = Dict(:max_attempts => 5, :lockout_duration => 1800, :success_redirect => "/", :fail_msg => "Username and/or password incorrect.")
config[:logout]         = Dict(:redirect => "/")
config[:pwdreset]       = Dict(:max_attempts => 5, :lockout_duration => 1800, :success_redirect => "/", :fail_msg => "Password incorrect.")
config[:securecookie]   = Dict{Symbol, Any}(:cookie_max_age => 5 * 60 * 1000,    # Duration of a session's validity in milliseconds
                                            :key_length     => 32,               # Key length for AES 256-bit cipher in CBC mode
                                            :block_size     => 16)               # IV  length for AES 256-bit cipher in CBC mode

### Includes
# Common
include("utils.jl")
include("configure.jl")
include("generic_handlers.jl")
# Sessions
include("sessions/secure_cookies.jl")
include("sessions/clientside_sessions.jl")
include("sessions/serverside_common.jl")
include("sessions/serverside_loggeddict.jl")
include("sessions/serverside_redis.jl")
# Authentication
include("backends/backends_common.jl")
include("backends/backend_loggeddict.jl")
include("authentication/authn_html.jl")
include("authentication/authn_handlers.jl")
include("authentication/authn_utils.jl")
include("authentication/passwordhash/password_hash.jl")
include("authentication/passwordhash/pbkdf2.jl")
# Authorization
include("authorization/authz_utils.jl")


### Start-up scripts
update_securecookie_config!(:cookie_max_age)
update_securecookie_config!(:key_length)
update_securecookie_config!(:block_size)

# Access control paths
acpaths = Dict{AbstractString, Function}()
acpaths["/login"]            = login!
acpaths["/logout"]           = logout!              # Redirect user according to cfg
acpaths["/reset_password"]   = reset_password!      # Display password reset form
acpaths["/process_pwdreset"] = process_pwdreset!    # Handle credentials supplied by user as part of password reset

end # module
