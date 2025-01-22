local protocol = require "lib/protocol"
local session = require "multiplayer/global"
local Player = require "multiplayer/client/classes/player"

local ClientHandlers = {}

ClientHandlers[ protocol.ServerMsg.ChunkData ] = function (packet)
    world.set_chunk_data(packet.x, packet.z, Bytearray(packet.data), true)
end

ClientHandlers[ protocol.ServerMsg.ChatMessage ] = function (packet)
    console.log("| "..packet.message)
end

ClientHandlers[ protocol.ServerMsg.StatusResponse ] = function (packet)
    console.log("| [SERVER] "..packet.name)
end

ClientHandlers[ protocol.ServerMsg.TimeUpdate ] = function (packet)
    world.set_day_time( packet.game_time )
end

ClientHandlers[ protocol.ServerMsg.PlayerJoined ] = function (packet)
    console.log("| [SERVER] "..packet.username.." Joined to Server!")
    session.client.players[packet.entity_id] = Player.new(packet.x, packet.y, packet.z, packet.entity_id)
end

ClientHandlers[ protocol.ServerMsg.PlayerMoved ] = function (packet)
    if packet.entity_id == session.client.entity_id then return end
    if not session.client.players[packet.entity_id] then
        session.client.players[packet.entity_id] = Player.new(packet.x, packet.y, packet.z, packet.entity_id)
    end

    session.client.players[packet.entity_id]:move(packet.x, packet.y, packet.z)
    session.client.players[packet.entity_id]:rotate(packet.yaw, packet.pitch)
end

ClientHandlers[ protocol.ServerMsg.KeepAlive ] = function (packet)
    session.client:push_packet( protocol.build_packet("client", protocol.ClientMsg.KeepAlive, packet.challenge) )
end

ClientHandlers[ protocol.ServerMsg.Disconnect ] = function (packet)
    local str = "Сервер кикнул вас"
            if packet.reason ~= "" then
                str = str.." по причине: "..packet.reason
            else str = str.."." end
            console.log(str)
            -- самоуничтожение
            session.client:disconnect()
end

ClientHandlers[ protocol.ServerMsg.BlockUpdate ] = function (packet)

    if packet.block_id == 0 then
        block.destruct(packet.x, packet.y, packet.z, -1)
    else
        block.place( packet.x, packet.y, packet.z, packet.block_id, packet.block_state, -1 )
    end

end

ClientHandlers[ protocol.ServerMsg.WorldData ] = function (packet)

    for key, value in ipairs(packet.data) do
        block.set( value.x, value.y, value.z, value.block_id, value.block_state )
    end

end

return ClientHandlers