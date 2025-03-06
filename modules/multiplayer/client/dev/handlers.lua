local protocol = require "lib/protocol"
require "multiplayer/global"
local Player = require "multiplayer/client/classes/player"
local list   = require "lib/common/list"
local api_events = require "api/events"
local WorldDataQueue = require "multiplayer/client/WorldDataQueue"

local ClientHandlers = {}

ClientHandlers[ protocol.ServerMsg.ChunkData ] = function (packet)
    world.set_chunk_data(packet.x, packet.z, Bytearray(packet.data), true)
end

ClientHandlers[ protocol.ServerMsg.PackEvent ] = function (packet)
    api_events.__emit__(packet.pack, packet.event, packet.bytes)
end

ClientHandlers[ protocol.ServerMsg.ChatMessage ] = function (packet)
    console.chat("| "..packet.message)
end

ClientHandlers[ protocol.ServerMsg.StatusResponse ] = function (packet)
    console.log("| [SERVER] "..packet.name)
end

ClientHandlers[ protocol.ServerMsg.TimeUpdate ] = function (packet)
    if world.is_open() then
        world.set_day_time( packet.game_time )
    end
end

local function search_player(player_table, player_id)
    local found_index = nil
    for i, _player in pairs(player_table) do
        if _player.entity_id == player_id then
            found_index = i
            break
        end
    end
    return found_index
end

ClientHandlers[ protocol.ServerMsg.PlayerJoined ] = function (packet)
    console.log("| [SERVER] "..packet.username.." Joined to Server!")
    if not search_player(Session.client.players, packet.entity_id) then
        Session.client.players[packet.entity_id] = Player.new(packet.x, packet.y, packet.z, packet.entity_id, packet.username)
    end
end

ClientHandlers[ protocol.ServerMsg.PlayerList ] = function (packet)
    for i, _player in ipairs(packet.list) do
        local player_index = search_player(Session.client.players, _player.entity_id)
        if not player_index then
            Session.client.players[_player.entity_id] = Player.new(0, 0, 0, _player.entity_id, _player.username, _player.entity_id ~= Session.player_id)
        end
    end
end

ClientHandlers[ protocol.ServerMsg.PlayerListAdd ] = function (packet)
    local player_index = search_player(Session.client.players, packet.entity_id)
    if not player_index then
        Session.client.players[packet.entity_id] = Player.new(0, 0, 0, packet.entity_id, packet.username, player_index ~= Session.player_id)
    end
end

ClientHandlers[ protocol.ServerMsg.PlayerListRemove ] = function (packet)
    local player_index = search_player(Session.client.players, packet.entity_id)
    if player_index then
        Session.client.players[packet.entity_id]:despawn()

        -- если не задать вручную, игрок не сможет быть создан заново
        Session.client.players[packet.entity_id] = nil
    end
end

ClientHandlers[ protocol.ServerMsg.PlayerMoved ] = function (packet)
    if packet.entity_id == Session.client.entity_id then return end
    if not Session.client.players[packet.entity_id] then return end

    Session.client.players[packet.entity_id]:move(packet.x, packet.y, packet.z)
    Session.client.players[packet.entity_id]:rotate(packet.yaw, packet.pitch)
end

ClientHandlers[ protocol.ServerMsg.KeepAlive ] = function (packet)
    Session.client:push_packet( protocol.build_packet("client", protocol.ClientMsg.KeepAlive, packet.challenge) )
end

ClientHandlers[ protocol.ServerMsg.Disconnect ] = function (packet)
    local str = "Сервер кикнул вас"
    if packet.reason ~= "" then
        str = str .. " по причине: " .. packet.reason
    else str = str .. "." end
    console.log(str)
    -- самоуничтожение
    Session.client:disconnect()
end

ClientHandlers[ protocol.ServerMsg.BlockUpdate ] = function (packet)

    if block.index(packet.block_id) == 0 then
        block.destruct(packet.x, packet.y, packet.z, -1)
    else
        block.place( packet.x, packet.y, packet.z, block.index(packet.block_id), packet.block_state, -1 )
    end

end

ClientHandlers[ protocol.ServerMsg.WorldData ] = function (packet)
    for index, value in ipairs(packet.data) do
        list.pushright( WorldDataQueue, value )
    end
    -- console.log("WorldData: "..packet.progress.."/"..packet.max_progress)
end

ClientHandlers[ protocol.ServerMsg.SynchronizePlayerPosition ] = function (packet)
    -- небольшой костыль: намеренно игнорируем пакет, если все параметры равны нулю
    if packet.x ~= 0 or packet.y ~= 0 or packet.z ~= 0 or packet.yaw ~= 0 or packet.pitch ~= 0 then
        player.set_pos(Session.player_id, packet.x, packet.y, packet.z)
        player.set_rot(Session.player_id, packet.yaw, packet.pitch, 0)
        Session.client.x = packet.x
        Session.client.y = packet.y
        Session.client.z = packet.z
        Session.client.yaw = packet.yaw
        Session.client.pitch = packet.pitch
        Session.client.moved = false
        Session.client.moved_thru_chunk = false
    end
    player.set_suspended(Session.player_id, false)
    player.set_loading_chunks(Session.player_id, true)
    Session.client.position_initialized = true
end

return ClientHandlers