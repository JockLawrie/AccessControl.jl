#=
    Contents: Example 1b: Display last visit with LoggedDict as database.
=#
using HttpServer
using AccessControl
using LoggedDicts

# Database
sessions = LoggedDict("sessions", "sessions.log", true)    # Logging turned off

# Handler
function home!(req, res)
    session_id = read_sessionid(req, "id")
    if session_id == ""                             # "id" cookie does not exist...session hasn't started...start a new session.
        session_id = create_session(sessions, res, "id")
        res.data   = "This is your first visit."
    else
        last_visit = get(sessions, session_id, "lastvisit")
        res.data   = "Welcome back. Your last visit was at $last_visit."
    end
    set!(sessions, session_id, "lastvisit", string(now()))
end
