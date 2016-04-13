module AccessControl

using HttpServer
using MbedTLS
using JSON

import Redis.get, LoggedDicts.set!

export
    create_session, read_session, write_session!, delete_session!,    # Client-side sessions
    read_sessionid, set!, get                                         # Server-side sessions


#export login!, logout!, user_reset_password!, notfound!, badrequest!, redirect!,    # Default handlers
#       is_logged_in, is_not_logged_in,                                              # utils
#       update_config!    # utils


# Config - to be updated by the app's call to AccessControl.configure()
config                   = Dict{Symbol, Any}()
config[:admin_password]  = nothing
config[:acdata]          = nothing    # No default data store for access control data
config[:session]         = Dict(:id_length => 32, :max_n_sessions => 1, :timeout => 600)
config[:login_config]    = Dict(:max_attempts => 5, :lockout_duration => 1800, :success_redirect => "/", :fail_msg => "Username and/or password incorrect.")
config[:logout_config]   = Dict(:redirect => "/")
config[:pwdreset_config] = Dict(:max_attempts => 5, :lockout_duration => 1800, :success_redirect => "/", :fail_msg => "Password incorrect.")
config[:securecookie]    = Dict{Symbol, Any}(:cookie_max_age => 5 * 60 * 1000,    # Duration of a session's validity in milliseconds
                                             :key_length     => 32,               # Key length for AES 256-bit cipher in CBC mode
                                             :block_size     => 16)               # IV  length for AES 256-bit cipher in CBC mode

# Sessions
include("securecookies/secure_cookies.jl")
include("sessions/clientside_sessions.jl")
include("sessions/serverside_sessions/serverside_common.jl")
include("sessions/serverside_sessions/serverside_loggeddict.jl")
include("sessions/serverside_sessions/serverside_redis.jl")

#include("configure.jl")
#include("default_forms.jl")
include("default_handlers.jl")
include("utils.jl")


update_securecookie_config!(:cookie_max_age)
update_securecookie_config!(:key_length)
update_securecookie_config!(:block_size)


# Access control paths
#acpaths = Dict{AbstractString, AbstractString}()
#acpaths["/login"]            = login!
#acpaths["/logout"]           = logout!              # Redirect user according to cfg
#acpaths["/reset_password"]   = reset_password!      # Display password reset form
#acpaths["/process_pwdreset"] = process_pwdreset!    # Handle credentials supplied by user as part of password reset


#=
    Functions that are determined by the app's call to AccessControl.configure()
    Specifically, these functions depend on the type of the app's access control data store
=#


# User create/delete
function create_user! end
function delete_user! end

# Password management
function set_password! end
function get_salt_hashedpwd end

# Role management
#function add_roles! end
#function remove_roles! end


end # module
