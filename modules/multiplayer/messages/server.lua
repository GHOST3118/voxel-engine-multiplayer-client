local build_message = require "multiplayer/messages/build_message"
local session = require "multiplayer/global"

local ServerMessage = {}

ServerMessage.TimeRequest = {}
function ServerMessage.TimeRequest.new()
    local schema = {
        Time = world.get_day_time()
    }

    return schema
end

ServerMessage.TimeResponse = {}
function ServerMessage.TimeResponse.new( request_uuid )
    local time = world.get_day_time()

    local schema = {
        Time = time
    }

    return build_message(request_uuid, schema)
end


return ServerMessage