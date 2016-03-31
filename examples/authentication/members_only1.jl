using HttpServer

function app(req::Request)
    res = Response()
    if req.resource == "/home"
        res.data = "This is the home page. Anyone can visit here."
    elseif req.resource == "/members_only"
        res.data = "This page displays information for members only."
    else
        res.status = 404
        res.data   = "Requested resource not found"
    end
    res
end

server = Server((req, res) -> app(req))
run(server, 8000)
