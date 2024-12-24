local Pipeline = require "lib/pipeline"
local session = require "multiplayer/global"
local CommandMessage = require "multiplayer/messages/command"
local ChunkMessage = require "multiplayer/messages/chunk"
local ServerMessage = require "multiplayer/messages/server"
local build_message= require "multiplayer/messages/build_message"

local MainPipe = Pipeline.new()

MainPipe:add_middleware(function (event)
    if event.payload.Status then
        local Status = CommandMessage.StatusResponse.new(event.request_uuid)

        session.server:queue_response( Status )
    end

    return event
end)

MainPipe:add_middleware(function (event)
    if event.payload.Players then
        local Players = CommandMessage.PlayersResponse.new(event.request_uuid)

        session.server:queue_response( Players )
    end

    return event
end)

MainPipe:add_middleware(function (event)
    if event.payload.Chunk then
        local Chunk = ChunkMessage.ChunkResponse.new( event.request_uuid, event.payload.Chunk.x, event.payload.Chunk.z )
        
        session.server:queue_response( Chunk )
    end

    return event
end)

MainPipe:add_middleware(function (event)
    if event.payload.Time then
        local Time = ServerMessage.TimeResponse.new( event.request_uuid )

        session.server:queue_response( Time )
    end

    return event
end)

return MainPipe