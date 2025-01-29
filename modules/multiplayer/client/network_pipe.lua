local Pipeline = require "lib/pipeline"
require "multiplayer/global"
local protocol = require "lib/protocol"
local Player = require "multiplayer/client/classes/player"
local data_buffer = require "core:data_buffer"
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
NetworkPipe:add_middleware(function ()

    local packet_count = 0
    local max_packet_count = 10

    local start_time = os.clock()

    while packet_count < max_packet_count do

        local length_bytes = Session.client.network:recieve_bytes(2)

        if length_bytes then
            local length_buffer = protocol.create_databuffer( length_bytes )
            local length = length_buffer:get_uint16()
            if length then
                local data_bytes_buffer = data_buffer()

                local data_bytes = Session.client.network:recieve_bytes( length )
                while not data_bytes do
                    data_bytes = Session.client.network:recieve_bytes( length )
                end
                data_bytes_buffer:put_bytes( data_bytes )
                while data_bytes_buffer:size() < length do
                    local data_bytes = Session.client.network:recieve_bytes( length - data_bytes_buffer:size() )
                    if data_bytes then
                        
                        data_bytes_buffer:put_bytes( data_bytes )
                    end
                end

                data_bytes = data_bytes_buffer:get_bytes()

                if data_bytes then
                    if not protocol.check_packet("server", data_bytes) then print("сервер нам отправил какую-то хуйню! казнить!!!") end
                    
                    local packet = protocol.parse_packet("server", data_bytes)

                    List.pushright(ReceivedPackets, packet)
                    packet_count = packet_count + 1
                else break end
            else break end
        else break end
    end

    local end_time = os.clock()
    print(  "Получено пакетов: "..packet_count.." за "..(end_time-start_time).." секунд." )
    return true
end)

-- Обрабатываем пакеты
NetworkPipe:add_middleware(function()
    while not List.is_empty(ReceivedPackets) do
        local packet = List.popleft(ReceivedPackets)

        Session.client.fsm:handle_event( packet )
    end
    return true
end)

-- Проверим, не отключились ли мы вдруг случаем
NetworkPipe:add_middleware(function ()
    if not Session.client then return false end
    if Session.client.network.socket and not Session.client.network.socket:is_alive() then
        console.log("Соединение прервано.")
        -- самоуничтожаемся!
        Session.client:disconnect()
        return false
    end
    return true
end)

-- Отправляем на очередь всё, что хотим отправить на сервер
NetworkPipe:add_middleware(function ()
    -- Убедимся, что мы не отсылаем пакеты движения во время логина.
    if Session.client.fsm.current_state == protocol.States.Active then
        
        if Session.client.moved then
            push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.PlayerPosition, Session.client.x, Session.client.y, Session.client.z, Session.client.yaw, Session.client.pitch))
            Session.client.moved = false
        end

        if Session.client.moved_thru_chunk then
            -- TODO: нормальная загрузка чанков
            push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.RequestChunk, Session.client.chunk_x, Session.client.chunk_z))
            -- раскомментировать для загрузки соседних чанков
            -- push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.RequestChunk, session.client.chunk_x+1, session.client.chunk_z))
            -- push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.RequestChunk, session.client.chunk_x-1, session.client.chunk_z))
            -- push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.RequestChunk, session.client.chunk_x, session.client.chunk_z+1))
            -- push_packet(ClientQueue, protocol.build_packet("client", protocol.ClientMsg.RequestChunk, session.client.chunk_x, session.client.chunk_z-1))
            Session.client.moved_thru_chunk = false
        end
    end
    return true
end)

-- Отправляем всё, что не отправили
NetworkPipe:add_middleware(function ()
    while not List.is_empty(ClientQueue) do
        local packet = List.popleft(ClientQueue)
        Session.client.network:send(packet)
    end
    return true
end)

return NetworkPipe
