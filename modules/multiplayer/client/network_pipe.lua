local Pipeline = require "lib/pipeline"
require "multiplayer/global"
local protocol = require "lib/protocol"
local Player = require "multiplayer/client/classes/player"

local data_buffer = require "lib/common/bit_buffer"

local bincode = require "lib/common/bincode"

local List = require "lib/common/list"

local ClientQueue = require "multiplayer/client/client_queue"
local ReceivedPackets = List.new()

local NetworkPipe = Pipeline.new()

local function push_packet(list, packet)
    local buffer = protocol.create_databuffer()
    buffer:put_packet(packet)
    List.pushright(list, buffer.bytes)
end

-- Принимаем все пакеты
NetworkPipe:add_middleware(function()
    local max_packet_count = 10


    local packet_count = Session.client:receive_packets(max_packet_count, ReceivedPackets)


    return true
end)

-- Обрабатываем пакеты
NetworkPipe:add_middleware(function()
    while not List.is_empty(ReceivedPackets) do
        local packet = List.popleft(ReceivedPackets)

        Session.client.fsm:handle_event(packet)
    end
    return true
end)

-- Проверим, не отключились ли мы вдруг случаем
NetworkPipe:add_middleware(function()
    if not Session.client then
        return false
    end
    if Session.client.network.socket and not Session.client.network.socket:is_alive() then
        console.log("Соединение прервано.")

        -- самоуничтожаемся!
        Session.client:disconnect()
        return false
    end
    return true
end)

-- Отправляем на очередь всё, что хотим отправить на сервер
NetworkPipe:add_middleware(function()
    -- Убедимся, что мы не отсылаем пакеты движения во время логина.
    if Session.client.fsm.current_state == protocol.States.Active then
        if Session.client.pos_moved and Session.client.position_initialized then
            local region_x = math.floor(Session.client.x / 32)
            local region_z = math.floor(Session.client.z / 32)
            if Session.client.region_pos.x ~= region_x or Session.client.region_pos.z ~= region_z then
                push_packet(ClientQueue,
                    protocol.build_packet("client", protocol.ClientMsg.PlayerRegion, region_x, region_z))

                Session.client.region_pos = {x = region_x, z = region_z}
            end

            push_packet(ClientQueue,
            protocol.build_packet("client", protocol.ClientMsg.PlayerPosition, {Session.client.x, Session.client.y,
                Session.client.z}))

            Session.client.pos_moved = false
        end

        if Session.client.rotation_moved then
            push_packet(ClientQueue,
            protocol.build_packet("client", protocol.ClientMsg.PlayerRotation, Session.client.yaw, Session.client.pitch))
            Session.client.rotation_moved = false
        end

        if Session.client.cheats_changed then
            push_packet(ClientQueue,
            protocol.build_packet("client", protocol.ClientMsg.PlayerCheats, Session.client.noclip, Session.client.flight))

            Session.client.cheats_changed = false
        end

        if Session.client.inv_changed then
            push_packet(ClientQueue,
            protocol.build_packet("client", protocol.ClientMsg.PlayerInventory, Session.client.inv))
            Session.client.inv_changed = false
        end

        if Session.client.hand_slot_changed then
            push_packet(ClientQueue,
            protocol.build_packet("client", protocol.ClientMsg.PlayerHandSlot, Session.client.hand_slot))
            Session.client.hand_slot_changed = false
        end

        if Session.client.moved_thru_chunk then
            -- TODO: нормальная загрузка чанков
            push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.RequestChunk,
                Session.client.chunk_x, Session.client.chunk_z))
            -- раскомментировать для загрузки соседних чанков
            -- push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.RequestChunk, Session.client.chunk_x+1, Session.client.chunk_z))
            -- push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.RequestChunk, Session.client.chunk_x-1, Session.client.chunk_z))
            -- push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.RequestChunk, Session.client.chunk_x, Session.client.chunk_z+1))
            -- push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.RequestChunk, Session.client.chunk_x, Session.client.chunk_z-1))
            Session.client.moved_thru_chunk = false
        end
    end
    return true
end)

-- Отправляем всё, что не отправили
NetworkPipe:add_middleware(function()
    while not List.is_empty(ClientQueue) do
        local packet = List.popleft(ClientQueue)
        Session.client.network:send(packet)
    end
    return true
end)

return NetworkPipe
