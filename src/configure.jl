#=
    Contents: Functions for processing the app's call to AccessControl.configure().
=#


function configure(acdata, login_config::Dict, logout_config::Dict, pwdreset_config)
    cfg["acdata"] = acdata
    set_acdata_getters_setters(acdata)
    update_config!("login_cfg",  login_config)
    update_config!("logout_cfg",  logout_config)
    if pwdreset_config == nothing 
	delete!(cfg, "pwdreset_cfg")
    else
	update_config!("pwdreset_cfg", pwdreset_config)
    end
end

configure(acdata, login_config, logout_config) = configure(acdata, login_config, logout_config, nothing)


"Overwrite the defaults of cfg[key] with dct."
function update_config!(key::AbstractString, dct::Dict)
    d = cfg[key]
    for k in keys(dct)
	d[k] = dct[key]
    end
end


function set_acdata_getters_setters(acdata)
    tp = typeof(acdata)
    if tp == LoggedDict
	include("backends/logged_dict.jl")
    else
	error("Your access control data store has a type that AccessControl.jl doesn't support...yet. Please file an issue at the AccessControl.jl github repo.")
    end
end


# EOF
