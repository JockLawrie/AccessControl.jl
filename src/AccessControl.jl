module AccessControl

using HttpCommon
using SecureSessions

export login!, logout!, notfound!, badrequest!, redirect!,    # Default handlers
       @notfound!,                                            # Macro versions of some default handlers
       is_logged_in, is_not_logged_in                         # utils


include("default_handlers.jl")
include("utils.jl")

# Globals
admin_password = ""


end # module
