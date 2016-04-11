#=
    Contents: Functions for generating a key and self-signed certificate.
=#

rel(filename::AbstractString, p::AbstractString) = joinpath(dirname(filename), p)

"Generates keys/server.key and keys/server.crt if they don't already exist."
function generate_key_cert(filename)
    if !isfile("keys/server.crt")
        @unix_only begin
	    run(`mkdir -p $(rel(filename, "keys"))`)
	    run(`openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $(rel(filename, "keys/server.key")) -out $(rel(filename, "keys/server.crt"))`)
        end
    end
end

# EOF
