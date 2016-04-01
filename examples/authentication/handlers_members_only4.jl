#=
    Contents: Handlers for members_only4.jl.
=#


function home_with_login_form!(req, res)
    s = "<p>This is the home page. Anyone can visit here.</p>
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
    res.data = s
end


"Members only message with a logout link."
function members_only!(req, res)
    username = get_session_cookie_data(req, "sessionid")
    is_not_logged_in(username) ? notfound!(res): 
    res.data = "<p>This page displays information for members only.</p>
                <br>
                <form action='logout' method='post'>
	            <input type='submit' value='Logout'/>
                </form>"
end
