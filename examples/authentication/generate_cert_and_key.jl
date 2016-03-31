# Generate a self-signed certificate and key for https (if they do not already exist)

rel(filename::AbstractString, p::AbstractString) = joinpath(dirname(filename), p)

function generate_cert_and_key(filename::AbstractString)
    if !isfile("keys/server.crt")
	@unix_only begin
	    run(`mkdir -p $(rel(filename, "keys"))`)
	    run(`openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $(rel(filename, "keys/server.key")) -out $(rel(filename, "keys/server.crt"))`)
	end
    end
end
