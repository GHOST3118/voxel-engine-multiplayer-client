local protocol = require "multiplayer:lib/protocol"
local Network = require "multiplayer:lib/network"
local data_buffer = require "core:data_buffer"

-- Функция для создания подключения к сети
local function create_network()
    return Network.new()
end

-- Функция для отправки пакета
local function send_packet(network, packet_data)
    local packet = protocol.create_databuffer()
    packet:put_packet(packet_data)
    network:send(packet.bytes)
end

-- Функция для выполнения handshake
local function perform_handshake(network)
    send_packet(network, protocol.build_packet("client", protocol.ClientMsg.HandShake, "0.26.0", protocol.data.version, protocol.States.Status))
    send_packet(network, protocol.build_packet("client", protocol.ClientMsg.StatusRequest) )
end

-- Функция для получения длины данных
local function receive_length(network)
    local length_bytes = network:recieve_bytes(2)
    
    while not length_bytes do
        length_bytes = network:recieve_bytes(2)
    end
    

    if not length_bytes then return 0 end

    local length_buffer = data_buffer()
    length_buffer:put_bytes(length_bytes)
    length_buffer:set_position(1)
    return length_buffer:get_uint16()
end

-- Функция для получения данных заданной длины
local function receive_data(network, length)
    local data_bytes_buffer = data_buffer()
    if not network:alive() then return 0 end
    local chunk_length = length
    

    while data_bytes_buffer:size() < length do
        local data_bytes = network:recieve_bytes(chunk_length)
        if data_bytes then
            data_bytes_buffer:put_bytes(data_bytes)
        end
    end

    return data_bytes_buffer
end

local function parse( buffer )
    local data_bytes = buffer:get_bytes()
    local packet = protocol.parse_packet("server", data_bytes)
    return packet
end

local handshake = {}

-- Основная функция выполнения всех этапов
function handshake.make(host, port, callback)
    local network = create_network()
    local packet = nil

    network:connect(host, port, function(_s)

        if _s then
            perform_handshake(network)

            local length = receive_length(network)
            local data = receive_data(network, length)
            if data then
                packet = parse( data )
                callback( packet )
                network:disconnect()
                return
            end

            callback( nil )
        end

        
    end)
end

return handshake