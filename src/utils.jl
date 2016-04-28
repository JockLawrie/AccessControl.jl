#=
    Contents: General utilities.
=#

"Returns true if the application is using secure cookies."
function using_secure_cookies()
    haskey(config, :securecookie)
end


function using_clientside_sessions()
    config[:session][:datastore] == :cookie
end


"Returns: nonce and newform, where newform is form with the nonce inserted as a hidden field."
function add_nonce_to_form(form::AbstractString)    
    nonce   = base64encode(csrng(config[:session][:id_length]))
    replc   = "<input type='hidden' id='' name='nonce' value=$nonce></form>"
    newform = replace(form, "</form>", replc)
    nonce,  newform
end


"""
Inserts a hidden field into the form that contains a nonce.
Records the nonce in the server-side session object, form_id => nonce.
"""
function add_nonce_to_form(form_id::AbstractString, form::AbstractString, session_id::AbstractString)
    nonce, newform = add_nonce_to_form(form)
    session_set!(session_id, "forms", form_id, nonce)    # Store nonce in session
    newform
end


"""
Inserts a hidden field into the form that contains a nonce.
Records the nonce in the client-side session object, form_id => nonce.
"""
function add_nonce_to_form(form_id::AbstractString, form::AbstractString, session::Dict)
    nonce, newform = add_nonce_to_form(form)
    session["forms"][form_id] = nonce
    newform
end


"Cryptographically secure RNG"
function csrng(numbytes::Integer)
    entropy = MbedTLS.Entropy()
    rng     = MbedTLS.CtrDrbg()
    MbedTLS.seed!(rng, entropy)
    rand(rng, numbytes)
end


"""
Convert number to byte array.
The implementation is a modified version of that found in Stack Overflow question 3076680.
"""
function num_to_bytearray(x)
    io = IOBuffer()
    write(io, x)
    seekstart(io)
    readbytes(io)
end


#=
"""
Returns true is password adheres to the following formatting rules:
  R1) Length at least 8 characters
  R2) At least 5 unique characters
  R3) At least 1 upper case letter
  R4) At least 1 lower case letter
  R5) At least 1 number
  R6) At least 1 special character
"""
function password_is_permissible(password)
    # Determine the truth values of rules 1 to 6.
    uniq = unique(password)
    n    = length(uniq)
    r1   = length(password) >= 8
    r2   = n >= 5
    r3   = false
    r4   = false
    r5   = false
    r6   = false
    for i = 1:n
	c     = Int(uniq[i])    # Integer representation of Char
	if c >= 65 && c <= 90
	    r3 = true
	elseif c >= 97 && c <= 122
	    r4 = true
	elseif c >= 48 && c <= 57
	    r5 = true
	else
	    r6 = true
	end
    end

    # Calculate result
    result = false
    if r1 && r2 && r3 && r4 && r5 && r6
	result = true
    end
    result
end
=#


# EOF
