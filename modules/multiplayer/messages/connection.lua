local build_message = require "multiplayer/messages/build_message"

local ConnectionMessage = {}

ConnectionMessage.Connect = {}
function ConnectionMessage.Connect.new(username, version)
    local schema = {
        Connect = { username = username, version = version or "0.25.2" },
    }

    return schema
end

ConnectionMessage.ConnectionAccepted = {}
function ConnectionMessage.ConnectionAccepted.new(request_uuid)
    local schema = {
        ConnectionAccepted = {},
    }

    return build_message(request_uuid, schema)
end

ConnectionMessage.ConnectionRejected = {}
function ConnectionMessage.ConnectionRejected.new(request_uuid, reason)
    local schema = {
        ConnectionRejected = { reason = reason },
    }

    return build_message(request_uuid, schema)
end

return ConnectionMessage