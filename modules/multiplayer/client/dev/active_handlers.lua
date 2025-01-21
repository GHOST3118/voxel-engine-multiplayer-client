local protocol = require "lib/protocol"
local ClientHandlers = require "multiplayer/client/dev/handlers"

local ActiveHandlers = {}

ActiveHandlers.on_event = function ( client )
    return function ( packet )
        -- if packet.packet_type ~= protocol.ServerMsg.TimeUpdate then
        --     debug.print( packet )
        -- end

        if ClientHandlers[packet.packet_type] then
            ClientHandlers[packet.packet_type]( packet )
        end
        
    end
end

return ActiveHandlers