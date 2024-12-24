local build_message = require "multiplayer/messages/build_message"
local session = require "multiplayer/global"

local ChunkMessage = {}

ChunkMessage.ChunkRequest = {}
function ChunkMessage.ChunkRequest.new(x, z)
    local schema = {
        Chunk = { x = x, z = z }
    }

    return schema
end

ChunkMessage.ChunkResponse = {}
function ChunkMessage.ChunkResponse.new( request_uuid, x, z )
    local chunk = world.get_chunk_data(x, z, true)

    local schema = {
        Chunk = ""
    }

    pcall( function () schema.Chunk = base64.encode(chunk) end )

    return build_message(request_uuid, schema)
end


return ChunkMessage