local protocol = require "lib/protocol"
local session = require "multiplayer/global"
local Player = require "multiplayer/client/classes/player"

local ActiveHandlers = {}

ActiveHandlers.on_event = function ( client )
    return function ( packet )
        
        if packet.packet_type == protocol.ServerMsg.ChunkData then
            world.set_chunk_data(packet.x, packet.z, Bytearray(packet.data), true)
        elseif packet.packet_type == protocol.ServerMsg.ChatMessage then
            console.log("| "..packet.message)
        elseif packet.packet_type == protocol.ServerMsg.StatusResponse then
            console.log("| [SERVER] "..packet.name)
        elseif packet.packet_type == protocol.ServerMsg.TimeUpdate then
            world.set_day_time( packet.game_time )
        elseif packet.packet_type == protocol.ServerMsg.PlayerJoined then
            console.log("| [SERVER] "..packet.username.." Joined to Server!")
            session.client.players[packet.entity_id] = Player.new(packet.x, packet.y, packet.z, packet.entity_id)
        elseif packet.packet_type == protocol.ServerMsg.PlayerMoved then
            if not session.client.players[packet.entity_id] then
                session.client.players[packet.entity_id] = Player.new(packet.x, packet.y, packet.z, packet.entity_id)
            end

            session.client.players[packet.entity_id]:move(packet.x, packet.y, packet.z)
            session.client.players[packet.entity_id]:rotate(packet.yaw, packet.pitch)

        elseif packet.packet_type == protocol.ServerMsg.PlayerLeft then
            session.client.players[packet.entity_id]:despawn()
        elseif packet.packet_type == protocol.ServerMsg.KeepAlive then
            
            client:push_packet( protocol.build_packet("client", protocol.ClientMsg.KeepAlive, packet.challenge) )
        elseif packet.packet_type == protocol.ServerMsg.Disconnect then
            local str = "Сервер кикнул вас"
            if packet.reason ~= "" then
                str = str.." по причине: "..packet.reason
            else str = str.."." end
            console.log(str)
            -- самоуничтожение
            session.client:disconnect()
        end
    end
end

return ActiveHandlers