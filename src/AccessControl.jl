module AccessControl

# Globals
admin_password = ""

# Export
export login!, logout!, notfound!, badrequest!, redirect!,    # Default handlers
       is_logged_in, is_not_logged_in                         # utils

# Deps
using SecureSessions
using URIParser

# Includes
include("default_handlers.jl")
include("utils.jl")


end # module
