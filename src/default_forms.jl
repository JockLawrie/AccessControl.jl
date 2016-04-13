#=
    Contents: Default HTML forms for access control.
=#


"""
Returns: default login form.
Ensures HTTP method is POST.
"""
function login_form()
    "<form action='login' method='post'>
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
	 <li><a href='logout'>Logout</a></li>
     </ul>"
end


function logout_pwdreset_links()
    "<ul>
         <li><a href='logout'>Logout</a></li>
         <li><a href='reset_password'>Reset Password</a></li>
     </ul>"
end
