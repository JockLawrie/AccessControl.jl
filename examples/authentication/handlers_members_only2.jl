#=
    Contents: Handlers for members_only2.jl.
=#


"Returns true if username and password are valid."
function login_credentials_are_valid(username::AbstractString, password::AbstractString)
    result = false
    if haskey(password_store, username)
	if password_is_valid(password, password_store[username])
	    result = true
	end
    end
    result
end


function home_with_login_form()
    "<p>This is the home page. Anyone can visit here.</p>
     <br>
     <br>
     <form action='login' method='post'>
         Username:<br>
	 <input type='text' id='username' name='username'/>
	 <br>
	 Password:<br>
	 <input type='password' id='password' name='password'/>
	 <br>
	 <input type='submit' value='Login'/>
     </form>"
end


"Members only message with a logout link."
function members_only()
    "<p>This page displays information for members only.</p>
     <br>
     <form action='logout' method='post'>
	 <input type='submit' value='Logout'/>
     </form>
    "
end
