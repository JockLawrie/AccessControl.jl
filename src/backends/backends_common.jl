#=
    Contents: Functions common to all backends.
=#


function create_user!(username::AbstractString, password::AbstractString, roles = Set{AbstractString}())
    create_user!(config[:acdata], username, password, roles)
end


function delete_user!(username::AbstractString)
    delete_user!(config[:acdata], username)
end


function add_sessionid_to_user!(username::AbstractString, session_id::AbstractString)
    add_sessionid_to_user!(config[:acdata], username, session_id)
end


function remove_sessionid_from_user!(username::AbstractString, session_id::AbstractString)
    remove_sessionid_from_user!(config[:acdata], username, session_id)
end


function get_n_sessions(acdata::LoggedDict, username::AbstractString)
    get_n_sessions(config[:acdata], username)
end


function set_password!(username::AbstractString, password::AbstractString)
    set_password!(config[:acdata], username, password)
end


function get_salt_hashedpwd(username::AbstractString)
    get_salt_hashedpwd(config[:acdata], username)
end


function add_role!(username::AbstractString, role::AbstractString)
    add_roles!(username, role)
end


function remove_role!(username::AbstractString, role::AbstractString)
    remove_roles!(username, role)
end


function add_roles!(username::AbstractString, roles...)
    add_roles!(config[:acdata], username, roles...)
end


function remove_roles!(username::AbstractString, roles...)
    remove_roles!(config[:acdata], username, roles...)
end


# EOF
