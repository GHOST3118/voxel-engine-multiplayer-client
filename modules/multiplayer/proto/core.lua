local data_buffer = require "core:data_buffer"

local Proto = {}

function Proto.send_text(network, data)
    local buffer = data_buffer()
    local length = data_buffer()
    buffer:put_string( data )
    length:put_uint32( buffer:size() )

    network:send_bytes(length:get_bytes())
    network:send(data)
end

function Proto.recv_text(network)
    local byte_length = network:recieve_bytes(4)

    if byte_length then
        local header = data_buffer(byte_length)
        local length = header:get_uint32()
        local payload = network:recieve(length)

        if payload then
            return payload
        else
            return nil
        end
    else
        return nil
    end
end

return Proto