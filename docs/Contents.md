# Contents

1. [Sessions](Sessions.md)
2. [Authentication](Authentication.md)
3. Authorization
4. Admin Access (read and write access control data)
    - Via GUI
    - Via command line
5. Deploying AccessControl as a stand-alone service

- [Appendix A: Secure Cookies](SecureCookies.md)
- [Appendix B: Password Hashing](PasswordHash.md)


## Todo

### Sessions
1. Implement support for server-side sessions with other databases.
2. Implement check for session timeout.
3. Rate limiting. Limit the number of requests that a user can make per minute. This is aimed at preventing denial-of-service attacks.
    - rate_limit:       Max number of requests per minute for the given session. Defaults to 100.
    - lockout_duration: Duration (in seconds) of lockout after rate_limit has been reached. Defaults to 1800 (30 mins).

### Authentication
1. login!: max_attempts, lockout
2. pwdreset!: max_attempts, lockout (use login settings)

### Password Hashing
1. Implement an API for enabling app developers to specify password rules.

### Secure cookies
1. Ensure that cookie attributes are being used correctly
2. Compress data before encrypting?
