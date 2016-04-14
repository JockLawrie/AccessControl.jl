# Password Hashing


## Functionality
- Password hashing; used for login.

## API
```julia
# Store password...add salt, then hash, then store in type StoredPassword.
immutable StoredPassword
    salt::Array{UInt8, 1}
    hashed_password::Array{UInt8, 1}
end

# A salt is randomly generated using a cryptographically secure RNG
sp = StoredPassword(password::AbstractString)
password_is_valid(password::AbstractString, sp::StoredPassword)    # Returns true if hash(sp.salt, password) == sp.hashed_password
```

## Security Protocol
A given password is hashed using the following algorithm:

1. Generate a 16 byte (128 bit) salt using a cryptographically secure RNG
2. Hash the salted password using the PBKDF2 algorithm with:
    - SHA-512 as the pseudorandom function
    - 5000 iterations
    - A 512-bit derived key length
