local protocol = require "multiplayer:lib/protocol"
local Network = require "lib/network"
local data_buffer = require "lib/common/data_buffer"

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
    local attempts = 500
    local length_bytes
    
    while attempts > 0 do
        length_bytes = network:recieve_bytes(2)

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
        end
    end
    return data_bytes_buffer
end

local function try_receive_data(network, length)
    local attempts = 500
    local data_bytes_buffer = data_buffer()

    while data_bytes_buffer:size() < length and attempts > 0 do
        local remaining = length - data_bytes_buffer:size()
        local data_bytes = network:recieve_bytes(remaining)
        if data_bytes then
            data_bytes_buffer:put_bytes(data_bytes)
        end
        attempts = attempts - 1
    end
    return data_bytes_buffer:get_bytes()
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


local Handshake = {}
Handshake.__index = Handshake

function handshake.create(host, port, func_success, func_failed)
    local self = setmetatable({}, Handshake)

    self.host = host
    self.port = port
    self.func_success = func_success
    self.func_failed = func_failed

    self.length = 0
    self.body = data_buffer()

    self.network = create_network()

    self.network:connect(host, port, function(success)
        if not success then
            return
        end

        perform_handshake(self.network)

    end)

    return self
end

function Handshake:tick()
    if self.network then
        while self.length == 0 do
            local length = receive_length(self.network)
            if length == 0 then
                
                return
            end
            self.length = length
        end

        while self.body:size() < self.length do
            local data = try_receive_data(self.network, self.length - self.body:size())
            if data then
                self.body:put_bytes(data)
            end
        end

        if self.body:size() == self.length then
            local packet = parse(self.body)
            if packet.packet_type == protocol.ServerMsg.StatusResponse then
                self.func_success(packet)
            else
                self.func_failed()
            end
        end
    end
end

return handshake

