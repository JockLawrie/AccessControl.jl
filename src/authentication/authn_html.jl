#=
    Contents: Default HTML forms for access control.
=#


"""
Returns: default login form.
Ensures HTTP method is POST.
"""
function login_form()
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
             //var reqdata  = 'username=' + username + '&password=' + password;

	     var reqdata  = JSON.stringify({'username': username, 'password': password});



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


"Returns: default pwdreset form for server-side session."
function pwdreset_form(session_id::AbstractString)
    form = pwdreset_form_no_nonce()
    add_nonce_to_form("pwdreset", form, session_id)
end


"Returns: default pwdreset form for client-side session."
function pwdreset_form(session::Dict)
    form = pwdreset_form_no_nonce()
    add_nonce_to_form("pwdreset", form, session)
end


function pwdreset_form_no_nonce()
    "<h2>Password reset.</h2>
     <br>
     <form id='pwdreset' onsubmit='pwdreset(); return false;' method='post'>
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
     </form>
     <script>
         function pwdreset() {
	     var nonce       = document.getElementById('pwdreset').elements['nonce'].value;
             var current_pwd = document.getElementById('current_pwd').value;
             var new_pwd     = document.getElementById('new_pwd').value;
             var new_pwd2    = document.getElementById('new_pwd2').value;
             var reqdata     = {'form_id': 'pwdreset', 'nonce': nonce, 'current_pwd': current_pwd, 'new_pwd': new_pwd, 'new_pwd2': new_pwd2};
	     reqdata         = JSON.stringify(reqdata);
             var xhr         = new XMLHttpRequest();
             xhr.onreadystatechange = function() {
	         if(xhr.readyState == 4) {
		     if(xhr.status == 200) {
		         window.location = xhr.responseText;
                     }
	             if(xhr.status == 400) { // Bad request
		         alert(xhr.responseText);
                     }
	             document.getElementById('current_pwd').value = '';    // Clear the input
	             document.getElementById('new_pwd').value     = '';
	             document.getElementById('new_pwd2').value    = '';
	         }
	     }
	     xhr.open('POST', '/process_pwdreset', true);
	     xhr.send(reqdata);
         }
     </script>"
end


# EOF
