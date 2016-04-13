# Contents

1. [Sessions](Sessions.md)
2. [Authentication](Authentication.md)
3. Authorization
4. [Admin Access](AdminAccess.md) (Read and write access control data)
5. Deploying AccessControl as a stand-alone service
- [Appendix A: Secure Cookies](SecureCookies.md)


## Todo

### Sessions
1. Implement support for server-side sessions with other databases.
2. Rate limiting. Limit the number of requests that a user can make per minute. This is aimed at preventing denial-of-service attacks.
    - rate_limit:       Max number of requests per minute for the given session. Defaults to 100.
    - lockout_duration: Duration (in seconds) of lockout after rate_limit has been reached. Defaults to 1800 (30 mins).

### Authentication
1. login!: max_attempts, lockout
2. pwdreset!: max_attempts, lockout (use login settings)
