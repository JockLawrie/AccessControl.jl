#=
    Contents: Default HTML forms for access control.
=#


"""
Returns: default login form.
Ensures HTTP method is POST.
"""
function login_form()
    "<form action='/login' method='post'>
	 Username:<br>
	 <input type='text' id='username' name='username'/>
	 <br>
	 Password:<br>
	 <input type='password' id='password' name='password'/>
	 <br>
	 <input type='submit' value='Login'/>
     </form>"
end


function logout_link()
    "<ul>
	 <li><a href='/logout'>Logout</a></li>
     </ul>"
end


function logout_pwdreset_links()
    "<ul>
         <li><a href='/logout'>Logout</a></li>
         <li><a href='/reset_password'>Reset Password</a></li>
     </ul>"
end


function pwdreset_form()
    "<h2>Password reset.</h2>
     <br>
     <form action='/process_pwdreset' method='post'>
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
