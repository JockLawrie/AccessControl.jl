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
    is_not_logged_in(username) && (notfound!(res); return)
    res.data = "<p>This page displays information for members only.</p>
                <br>
		<ul>
		    <li><a href='logout'>Logout</a></li>
		    <li><a href='reset_password'>Reset Password</a></li>
		</ul>"
end


function reset_password!(req, res)
    username = get_session_cookie_data(req, "sessionid")
    is_not_logged_in(username) && (notfound!(res); return)
    res.data = "<h2>Password reset.</h2>
                <br>
		<form action='user_reset_password' method='post'>
	            Current password:<br>
	            <input type='password' id='current_pwd' name='current_pwd'/>
	            <br>
	            New password:<br>
	            <input type='password' id='new_pwd' name='new_pwd'/>
	            <br>
	            Retype new password:<br>
	            <input type='password' id='new_pwd2' name='new_pwd2'/>
	            <br>
                    <input type='submit' value='Reset Password'/>
		</form>"
end
