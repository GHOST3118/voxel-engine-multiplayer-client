local Pipeline = require "lib/pipeline"
require "multiplayer/global"
local protocol = require "lib/protocol"

local List = require "lib/common/list"

local ServerPipe = Pipeline.new()

local function push_packet(list, packet)
    local buffer = protocol.create_databuffer()
    buffer:put_packet(packet)
    List.pushright(list, buffer.bytes)
end

local function chat(list, msg)
    -- хочу чтобы эта функция отправляла сообщение только одному клиенту (на будущее)
    push_packet(list, protocol.build_packet("server", protocol.ServerMsg.ChatMessage, 0, msg, 0))
end

local function global_chat(msg)
    console.log("| " .. msg)
    for _, client in ipairs(Session.server.clients) do
        if client.active then
            push_packet(client.response_queue, protocol.build_packet("server", protocol.ServerMsg.ChatMessage, 0, msg, 0))
        end
    end
end

-- Принимаем все пакеты
ServerPipe:add_middleware(function(client)
    local packet_count = 0
    local max_packet_count = 10
    while packet_count < max_packet_count do
        local length_bytes = client.network:recieve_bytes(2)
        if length_bytes then
            local length_buffer = protocol.create_databuffer(length_bytes)
            local length = length_buffer:get_uint16()
            if length then
                local data_bytes = client.network:recieve_bytes(length)
                if data_bytes then
                    if not protocol.check_packet("client", data_bytes) then print("клиент нам отправил какую-то хуйню! казнить!!!") end
                    local packet = protocol.parse_packet("client", data_bytes)
                    List.pushright(client.received_packets, packet)
                    packet_count = packet_count + 1
                else break end
            else break end
        else break end
    end
    return client
end)

-- TODO: перевести на новый протокол
-- Обрабатываем пакеты
ServerPipe:add_middleware(function(client)
    while not List.is_empty(client.received_packets) do
        local packet = List.popleft(client.received_packets)


        -- STATE: LOGIN
        if client.active == false then
            if packet.packet_type == protocol.ClientMsg.Connect then
                -- TODO: проверка на уникальность имени
                push_packet(client.response_queue, protocol.build_packet("server", protocol.ServerMsg.ConnectionAccepted))
                client.username = packet.username
                client.active = true
                global_chat(packet.username .. " присоединился к игре.")
            else
                -- уничтожаем клиент, ибо мы не ждали чего-то другого
                local buffer = protocol.create_databuffer()
                buffer:put_packet(protocol.build_packet("server", protocol.ServerMsg.ConnectionRejected,
                    "Wrong packet type at state LOGIN"))
                client.network:send(buffer.bytes)
                -- client.network:disconnect() -- сообщение не успевает обработаться =(
                return false
            end


            -- STATE: ACTIVE
        elseif client.active == true then
            if packet.packet_type == protocol.ClientMsg.ChatMessage then
                global_chat("<" .. client.username .. "> " .. packet.message)
            elseif packet.packet_type == protocol.ClientMsg.RequestChunk then
                local chunkdata = world.get_chunk_data(packet.x, packet.z, true)
                if chunkdata then -- предотвращение ошибки если вдруг чанк не прогружен сервером
                    push_packet(client.response_queue, protocol.build_packet("server", protocol.ServerMsg.ChunkData, packet.x, packet.z, chunkdata))
                end
            end
        end
    end
    return client
end)

-- TODO: Проверим, не отключился ли вдруг клиент
-- оказалось, такая проверка уже есть при старте процессинга трубы.

-- TODO: Отправляем на очередь всё, что хотим отправить клиенту

-- Отправляем всё, что не отправили
ServerPipe:add_middleware(function(client)
    while not List.is_empty(client.response_queue) do
        local packet = List.popleft(client.response_queue)
        client.network:send(packet)
    end
    return client
end)

return ServerPipe
