#=
    Contents: Functions for processing the app's call to AccessControl.configure().
=#


"""
Updates the default config from that defined in AccessControl.jl to that defined by the args.

NOTE: Only the keys specified in the args are updated, other keys will retain their default values.
"""
function update_config!(acdata;
                        securecookie = Dict{Symbol, Any}(), session = Dict{Symbol, Any}(),
                        login = Dict{Symbol, Any}(), logout = Dict{Symbol, Any}(), pwdreset = Dict{Symbol, Any}())
    update_config_acdata!(acdata)
    update_config!(:securecookie, securecookie_config)
    update_config!(:session,      session_config)
    update_config!(:login,        login_config)
    update_config!(:logout,       logout_config)
    update_config!(:pwdreset,     pwdreset_config)
end


"Overwrite the defaults of cfg[key] with dct."
function update_config!(k1::Symbol, dct::Dict)
    for k2 in keys(dct)
	update_config!(k1, k2, dct[k2])
    end
end


"Update config and trigger update of downstream values."
function update_config!(k1::Symbol, k2::Symbol, val)
    config[k1][k2] = val
    if k1 == :securecookie
	update_securecookie_config!(k2)
    end
end


function update_config_acdata!(acdata)
    config[:acdata] = acdata
    include_acdata_backend_support(acdata)
end


function include_acdata_backend_support(acdata::LoggedDict)
    include("backends/logged_dict.jl")
end


"Called if typeof(acdata) is not yet supported."
function include_acdata_backend_support(acdata)
    error("Your access control data store has a type that AccessControl.jl doesn't yet support. Please file an issue at the AccessControl.jl github repo.")
end


# EOF
