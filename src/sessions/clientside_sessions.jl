#=
    Contents: Create, read and delete functions for client-side sessions.
=#


"""
Returns a Dict with:
- 'id'        => session_id, which is randomly generated using a cryptographically secure RNG.
- 'username'  => username 
"""
function session_create!(username::AbstractString)
    get_n_sessions(username) >= config[:session][:max_n_sessions] && return Dict()
    result             = Dict{AbstractString, Any}()
    result["id"]       = generate_session_id()
    result["username"] = username
    if haskey(config[:session], :timeout)
	update_lastreq!(result)
    end
    result
end


"Read the session from the specified cookie."
function session_read(req::Request)
    s = ""
    cookiename = config[:session][:cookiename]
    if using_secure_cookies()
	s = get_securecookie_data(req, cookiename)
    else
	s = get_cookie_value(req, cookiename)
    end

    # Check whether session has timed out
    if s != ""
	session = JSON.parse(s)
	if session_is_valid(session)
	    s = session
	else
	    s = ""
	end
    end

    # Update session["lastreq"]
    s != "" && update_lastreq!(s)
    s
end

"Write the session object to the specified cookie."
function session_write!(res::Response, session::Dict)
    cookiename = config[:session][:cookiename]
    write_to_cookie!(res, cookiename, JSON.json(session))
end


"Set the specified cookie to an invalid state."
function session_delete!(res::Response)
    cookiename = config[:session][:cookiename]
    invalidate_cookie!(res, cookiename)
end


"""
Returns true if the session:
    - has a session ID, and
    - hasn't timed out
"""
function session_is_valid(session::Dict)
    result = true
    if !haskey(session, "id")
	result = false
    elseif !haskey(session, "username")
	result = false
    elseif haskey(config[:session], :timeout)
	if haskey(session, "lastreq")
	    dt = DateTime(session["lastreq"])
	    if dt + Dates.Second(config[:session][:timeout]) < now()
		result = false    # Session has timed out
	    end
	else
	    result = false
	end
    end
    result
end


function update_lastreq!(session::Dict)
    session["lastreq"] = string(now())
end


################################################################################
### Utils

function generate_session_id()
    base64encode(csrng(config[:session][:id_length]))
end

function write_to_cookie!(res::Response, cookiename::AbstractString, data::AbstractString)
    using_secure_cookies() ? set_securecookie!(res, cookiename, data) : setcookie!(res, cookiename, data)
end


# EOF
