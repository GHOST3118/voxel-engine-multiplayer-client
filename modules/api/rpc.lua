local events = start_require "api/events"
local bson = require "lib/common/bson"
local db = require "lib/common/bit_buffer"

local module = {
    emitter = {},
    handler = {}
}

function module.emitter.create_send(pack, event)
    return function (...)
        local buffer = db:new()
        bson.encode(buffer, {...})

        events.send(pack, event, buffer.bytes)
    end
end

return module