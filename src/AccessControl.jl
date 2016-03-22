module AccessControl

# Globals
passwd = ""
seclvl = "0_no_admin"

# Export
export access_control

# Deps
using SecureSessions
using URIParser

# Includes
include("main_access_control.jl")

end # module
