module AccessControl

using HttpCommon
using SecureSessions

export login!, logout!, user_reset_password!, notfound!, badrequest!, redirect!,    # Default handlers
       is_logged_in, is_not_logged_in                         # utils

include("default_handlers.jl")
include("utils.jl")

# Globals
admin_password = ""

# To be defined by the user
function get_salt_hashedpwd end
function set_password! end

end # module
