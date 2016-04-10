#=
    Contents: Constants
=#


const login_form = "
    <form action='login' method='post'>
        Username:<br>
        <input type='text' id='username' name='username'/>
        <br>
        Password:<br>
        <input type='password' id='password' name='password'/>
        <br>
        <input type='submit' value='Login'/>
    </form>"


const logout = "
    <ul>
        <li><a href='logout'>Logout</a></li>
    </ul>"


const logout_pwdreset = "
    <ul>
        <li><a href='logout'>Logout</a></li>
        <li><a href='reset_password'>Reset Password</a></li>
    </ul>"
