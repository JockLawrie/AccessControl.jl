#=
    Contents: Gernal utilities.
=#

"Returns true if the application is using secure cookies."
function using_secure_cookies()
    haskey(config, :securecookie)
end


"Cryptographically secure RNG"
function csrng(numbytes::Integer)
    entropy = MbedTLS.Entropy()
    rng     = MbedTLS.CtrDrbg()
    MbedTLS.seed!(rng, entropy)
    rand(rng, numbytes)
end


# EOF
