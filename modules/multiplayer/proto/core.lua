local data_buffer = require "core:data_buffer"
local utils   = require "lib/utils"

local Proto = {}

function Proto.send_text(network, data)
    local buffer = data_buffer()
    local payload = data_buffer()

    payload:set_bytes( utf8.tobytes(data) )
    buffer:put_uint16( payload:size() )

    network:send(buffer:get_bytes())
    network:send(data)
    print("Отправили:",data)
end

function Proto.recv_text(network)
    local byte_length = network:recieve_bytes(2)

    if byte_length then
        local header = data_buffer(byte_length)
        local length = header:get_uint16()
        local payload = network:recieve(length)

        if payload then
            print("Получили:",payload)
            return payload
        else
            return nil
        end
    else
        return nil
    end
end

return Proto