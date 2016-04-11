module AccessControl
#=
TODO:
- login!: max_attempts, lockout
- pwdreset!: max_attempts, lockout (use login settings)
=#

using HttpCommon
using JSON

export login!, logout!, user_reset_password!, notfound!, badrequest!, redirect!,    # Default handlers
       is_logged_in, is_not_logged_in                                               # utils


include("constants.jl")
include("configure.jl")
include("default_handlers.jl")
include("utils.jl")


# Config - to be updated by the app's call to AccessControl.configure()
cfg                   = Dict{AbstractString, Any}()
#cfg["admin_password"] = nothing
cfg["acdata"]         = nothing    # No default data store for access control data
cfg["login_cfg"]      = Dict("max_attempts" => 5, "lockout_duration" => 1800, "success_redirect" => "/", "fail_msg" => "Username and/or password incorrect.")
cfg["logout_cfg"]     = Dict("redirect" => "/")
cfg["pwdreset_cfg"]   = Dict("max_attempts" => 5, "lockout_duration" => 1800, "success_redirect" => "/", "fail_msg" => "Password incorrect.")


# Access control paths
acpaths = Dict{AbstractString, AbstractString}()
acpaths["/login"]            = login!
acpaths["/logout"]           = logout!              # Redirect user according to cfg
acpaths["/reset_password"]   = reset_password!      # Display password reset form
acpaths["/process_pwdreset"] = process_pwdreset!    # Handle credentials supplied by user as part of password reset


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
