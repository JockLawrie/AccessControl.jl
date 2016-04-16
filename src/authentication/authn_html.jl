#=
    Contents: Default HTML forms for access control.
=#


"""
Returns: default login form.
Ensures HTTP method is POST.
"""
function login_form()
    #"<form action='/login' method='post'>
    "<form onsubmit='login(); return false;' method='post'>
	 Username:<br>
	 <input type='text' id='username' name='username'/>
	 <br>
	 Password:<br>
	 <input type='password' id='password' name='password'/>
	 <br>
	 <input type='submit' value='Login'/>
     </form>
     <script>
         function login() {
             var username = document.getElementById('username').value;
             var password = document.getElementById('password').value;
             var reqdata  = 'username=' + username + '&password=' + password;
             var xhr      = new XMLHttpRequest();
             xhr.onreadystatechange = function() {
	         if(xhr.readyState == 4) {
		     if(xhr.status == 200) {
		         window.location = xhr.responseText;
                     }
	             if(xhr.status == 400) { // Bad request
		         alert(xhr.responseText);
                     }
	             document.getElementById('username').value = '';    // Clear the input
	             document.getElementById('password').value = '';
	         }
	     }
	     xhr.open('POST', '/login', true);
	     xhr.send(reqdata);
         }
     </script>"
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
