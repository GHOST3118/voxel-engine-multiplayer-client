local Pipeline = require "lib/pipeline"
local session = require "multiplayer/global"
local data_buffer = require "core:data_buffer"

local NetworkPipe = Pipeline.new()

NetworkPipe:add_middleware(function ()
    local length_bytes = session.client.network:recieve_bytes(2)
    print (length_bytes)
    if length_bytes then
        local length_buffer = data_buffer( length_bytes )
        local length = data_buffer:get_uint16()
        if length then
            local data_bytes = session.client.network:recieve_bytes( length )
            if data_bytes then
                local data_as_buffer = data_buffer( data_bytes )
                print( data_as_buffer:get_byte() )
            end
        end
    end
end)

return NetworkPipe
