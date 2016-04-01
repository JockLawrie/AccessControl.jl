module AccessControl

using HttpCommon
using SecureSessions

export login!, logout!, notfound!, badrequest!, redirect!,    # Default handlers
       is_logged_in, is_not_logged_in                         # utils


include("default_handlers.jl")
include("utils.jl")

# Globals
admin_password = ""

function get_salt_hashedpwd end    # To be defined by the user

end # module
