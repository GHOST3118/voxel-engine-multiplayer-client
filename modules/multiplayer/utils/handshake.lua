local protocol = require "multiplayer:lib/protocol"
local Network = require "lib/network"
local data_buffer = require "core:data_buffer"

local function create_network()
    return Network.new()
end

local function send_packet(network, packet_data)
    local packet = protocol.create_databuffer()
    packet:put_packet(packet_data)
    network:send(packet.bytes)
end

local function perform_handshake(network)
    send_packet(network, protocol.build_packet("client", protocol.ClientMsg.HandShake, "0.26.0", protocol.data.version, protocol.States.Status))
    send_packet(network, protocol.build_packet("client", protocol.ClientMsg.StatusRequest))
end

local function receive_length(network)
    local attempts = 100
    local length_bytes
    
    while attempts > 0 do
        length_bytes = network:recieve_bytes(2)
        debug.print(length_bytes)
        if length_bytes then break end
        attempts = attempts - 1
    end
    
    if not length_bytes then return 0 end
    
    local length_buffer = data_buffer()
    length_buffer:put_bytes(length_bytes)
    length_buffer:set_position(1)
    return length_buffer:get_uint16()
end

local function receive_data(network, length)
    local data_bytes_buffer = data_buffer()
    while data_bytes_buffer:size() < length do
        local remaining = length - data_bytes_buffer:size()
        local data_bytes = network:recieve_bytes(remaining)
        if data_bytes then
            data_bytes_buffer:put_bytes(data_bytes)
        else
            return nil
        end
    end
    return data_bytes_buffer
end

local function parse(buffer)
    local data_bytes = buffer:get_bytes()
    return protocol.parse_packet("server", data_bytes)
end

local handshake = {}

function handshake.make(host, port, callback)
    local network = create_network()
    network:connect(host, port, function(success)
        if not success then
            callback(nil)
            return
        end
        
        perform_handshake(network)
        local length = receive_length(network)
        if length == 0 then
            callback(nil)
            return
        end
        local data = receive_data(network, length)
        if data then
            callback(parse(data))
        else
            callback(nil)
        end
        network:disconnect()
    end)
end

return handshake

