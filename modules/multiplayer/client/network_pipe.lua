local Pipeline = require "lib/pipeline"
local session = require "multiplayer/global"
local protocol = require "lib/protocol"
local Player = require "multiplayer/client/classes/player"

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
NetworkPipe:add_middleware(function ()
    local packet_count = 0
    local max_packet_count = 10
    while packet_count < max_packet_count do
        local length_bytes = session.client.network:recieve_bytes(2)
        if length_bytes then
            local length_buffer = protocol.create_databuffer( length_bytes )
            local length = length_buffer:get_uint16()
            -- debug.print("length", length, "\nlength_bytes", length_bytes)
            if length then
                local data_bytes = session.client.network:recieve_bytes( length )
                if data_bytes then
                    if not protocol.check_packet("server", data_bytes) then print("сервер нам отправил какую-то хуйню! казнить!!!") end
                    local packet = protocol.parse_packet("server", data_bytes)
                    List.pushright(ReceivedPackets, packet)
                    packet_count = packet_count + 1
                else break end
            else break end
        else break end
    end
    return true
end)

-- Обрабатываем пакеты
NetworkPipe:add_middleware(function()
    while not List.is_empty(ReceivedPackets) do
        local packet = List.popleft(ReceivedPackets)


        -- STATE: LOGIN
        if session.client.state == "LOGIN" then
            --
            if packet.packet_type == protocol.ServerMsg.ConnectionAccepted then
                console.log("Подключение успешно!")
                session.client.state = "ACTIVE"
            else
                local str = ""
                if packet.packet_type == protocol.ServerMsg.ConnectionRejected or packet.packet_type == protocol.ServerMsg.Disconnect then
                    str = "Сервер отказал в подключении."
                    if packet.reason then str = str .. " Причина: " .. packet.reason end
                else
                    str = "Сервер отправил какую-то ерунду вместо ожидаемых данных. Соединение разорвано."
                end
                console.log(str)
                -- самоуничтожаемся!
                session.client:disconnect()
                return false
            end


        -- STATE: ACTIVE
        elseif session.client.state == "ACTIVE" then
            if packet.packet_type == protocol.ServerMsg.ChunkData then
                world.set_chunk_data(packet.x, packet.z, Bytearray(packet.data), true)
            elseif packet.packet_type == protocol.ServerMsg.ChatMessage then
                console.log("| "..packet.message)
            elseif packet.packet_type == protocol.ServerMsg.PlayerJoined then
                session.client.players[packet.client_id] = Player.new(packet.x, packet.y, packet.z, packet.client_id, packet.username)
            elseif packet.packet_type == protocol.ServerMsg.PlayerMoved then
                session.client.players[packet.client_id]:move(packet.x, packet.y, packet.z)
                session.client.players[packet.client_id]:rotate(packet.yaw, packet.pitch)
            elseif packet.packet_type == protocol.ServerMsg.PlayerLeft then
                session.client.players[packet.client_id]:despawn()
            elseif packet.packet_type == protocol.ServerMsg.KeepAlive then
                push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.KeepAlive, packet.challenge))
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
    return true
end)

-- Проверим, не отключились ли мы вдруг случаем
NetworkPipe:add_middleware(function ()
    if session.client.network.socket and not session.client.network.socket:is_alive() then
        console.log("Соединение прервано.")
        -- самоуничтожаемся!
        session.client:disconnect()
        return false
    end
    return true
end)

-- Отправляем на очередь всё, что хотим отправить на сервер
NetworkPipe:add_middleware(function ()
    -- Убедимся, что мы не отсылаем пакеты движения во время логина.
    if session.client.state == "ACTIVE" then
        if session.client.moved then
            push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.PlayerPosition, session.client.x, session.client.y, session.client.z, session.client.yaw, session.client.pitch))
            session.client.moved = false
        end

        if session.client.moved_thru_chunk then
            -- TODO: нормальная загрузка чанков
            push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.RequestChunk, session.client.chunk_x, session.client.chunk_z))
            -- раскомментировать для загрузки соседних чанков
            -- push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.RequestChunk, session.client.chunk_x+1, session.client.chunk_z))
            -- push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.RequestChunk, session.client.chunk_x-1, session.client.chunk_z))
            -- push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.RequestChunk, session.client.chunk_x, session.client.chunk_z+1))
            -- push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.RequestChunk, session.client.chunk_x, session.client.chunk_z-1))
            session.client.moved_thru_chunk = false
        end
    end
    return true
end)

-- Отправляем всё, что не отправили
NetworkPipe:add_middleware(function ()
    while not List.is_empty(ClientQueue) do
        local packet = List.popleft(ClientQueue)
        session.client.network:send(packet)
    end
    return true
end)

return NetworkPipe
