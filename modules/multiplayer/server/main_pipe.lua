local Pipeline = require "lib/pipeline"
local session = require "multiplayer/global"
local CommandMessage = require "multiplayer/messages/command"

local MainPipe = Pipeline.new()

MainPipe:add_middleware(function (event)
    if event.payload.Status then
        local Status = CommandMessage.StatusResponse.new(event.request_uuid)

        session.server:queue_response( Status )
    end

    return event
end)

MainPipe:add_middleware(function (event)
    if event.payload.Players then
        local Players = CommandMessage.PlayersResponse.new(event.request_uuid)

        session.server:queue_response( Players )
    end

    return event
end)

return MainPipe