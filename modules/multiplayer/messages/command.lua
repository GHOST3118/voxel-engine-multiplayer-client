local build_message = require "multiplayer/messages/build_message"
local session = require "multiplayer/global"

local CommandMessage = {}

CommandMessage.StatusRequest = {}
function CommandMessage.StatusRequest.new()
    local schema = {
        Status = true
    }

    return schema
end

CommandMessage.StatusResponse = {}
function CommandMessage.StatusResponse.new( request_uuid )
    local schema = {
        Status = "[server] connected"
    }

    return build_message(request_uuid, schema)
end

CommandMessage.PlayersResponse = {}
function CommandMessage.PlayersResponse.new( request_uuid )
    local schema = {
        Players = {}
    }

    for index, player in ipairs(session.server.clients) do
        if player.active then
            table.insert(schema.Players, {username = player.username})
        end
    end

    return build_message(request_uuid, schema)
end

return CommandMessage