local ConnectionMessage = {}

ConnectionMessage.Connect = {}
function ConnectionMessage.Connect.new(username, version)
    local schema = {
        Connect = { username = username, version = version or "0.25.2" },
    }

    return json.tostring( schema )
end

ConnectionMessage.ConnectionAccepted = {}
function ConnectionMessage.ConnectionAccepted.new(client_id)
    local schema = {
        ConnectionAccepted = { client_id = client_id },
    }

    return json.tostring( schema )
end

ConnectionMessage.ConnectionRejected = {}
function ConnectionMessage.ConnectionRejected.new(reason)
    local schema = {
        ConnectionRejected = { reason = reason },
    }

    return json.tostring( schema )
end

return ConnectionMessage