local Pipeline = require "lib/pipeline"
local session = require "multiplayer/global"
local Proto = require "multiplayer/proto/core"

local List = require "lib/common/list"

local ClientQueue = require "multiplayer/client/client_queue"

local NetworkPipe = Pipeline.new()

NetworkPipe:add_middleware(function()
    local request = {
        events = {}
    }

    while not List.is_empty(ClientQueue) do
        table.insert( request.events, List.popleft( ClientQueue ) )
    end

    Proto.send_text( session.client.network, json.tostring(request) )

    return true
end)

NetworkPipe:add_middleware(function()
    if not session.client then
        return nil
    end

    local data = Proto.recv_text( session.client.network )

    if data and pcall(function()
        json.parse(data)
    end) then
        return json.parse(data)
    end
    return nil
end)


NetworkPipe:add_middleware(function(data)
    local events = data.events
    if events then
        for index, event in ipairs(events) do

            if event and event.payload then
                local request_uuid = event.request_uuid
                if session.client.handlers[request_uuid] then
                    session.client.handlers[request_uuid](event.payload)
                end
            end
        end
    end

    return data
end)



return NetworkPipe
