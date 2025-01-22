app.config_packs({"base", "multiplayer"})
app.load_content()

menu.page = "servers"

events.on("connect", function(username, host, port)
    local protocol = require "multiplayer:lib/protocol"
    local Network = require "multiplayer:lib/network"
    local data_buffer = require "core:data_buffer"

    local network = Network.new()
    local status
    network:connect(host, port, function(_status)
        local packet = protocol.create_databuffer()
        packet:put_packet(protocol.build_packet("client", protocol.ClientMsg.HandShake, "0.26.0", protocol.data.version,
            protocol.States.Status))
        network:send(packet.bytes)

        packet = protocol.create_databuffer()
        packet:put_packet(protocol.build_packet("client", protocol.ClientMsg.StatusRequest))
        network:send(packet.bytes)

        local length_bytes = network:recieve_bytes(2)
        local length_buffer = data_buffer()
        while not length_bytes and network:alive() do
            length_bytes = network:recieve_bytes(2)
        end
        length_buffer:put_bytes(length_bytes)
        length_buffer:set_position(1)
        local length = length_buffer:get_uint16()

        local data_bytes_buffer = data_buffer()

        local data_bytes = network:recieve_bytes(length)
        while not data_bytes and network:alive() do
            data_bytes = network:recieve_bytes(length)
        end
        data_bytes_buffer:put_bytes(data_bytes)
        while data_bytes_buffer:size() < length and network:alive() do
            local data_bytes = network:recieve_bytes(length - data_bytes_buffer:size())
            if data_bytes then

                data_bytes_buffer:put_bytes(data_bytes)
            end
        end

        
        data_bytes = data_bytes_buffer:get_bytes()
        debug.print( data_bytes )
        local packet = protocol.parse_packet("server", data_bytes)

        debug.print(packet)

        app.new_world("", packet.seed, "base:demo", 0)
        console.execute("cu "..username)
        console.execute("connect \""..host.."\" "..port)
    end)

    
end)
