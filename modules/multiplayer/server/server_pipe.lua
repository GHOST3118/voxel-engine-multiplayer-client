local Pipeline = require "lib/pipeline"
local Proto = require "multiplayer/proto/core"
local Network = require "lib/network"
local AuthPipe = require "multiplayer/server/auth_pipe"
local MainPipe = require "multiplayer/server/main_pipe"
local List = require "lib/common/list"

local ServerPipe = Pipeline.new()

ServerPipe:add_middleware(function(client)
    local data = Proto.recv_text(client.network)

    if data then
        if pcall(function()
            json.parse(data)
        end) then

            local message = json.parse(data)
            if message then
                message.client = client
                return message
            end
        end
    end

    return nil
end)

ServerPipe:add_middleware(function(message)
    local client = message.client
    local network = client.network
    local events = message.events
    local status, username = client.active, client.username

    for index, event in ipairs(events) do
        if event.payload.Connect then
            local auth_data = {
                __client = client,
                __network = network,
                event = event
            }
            status, username = unpack(AuthPipe:process( auth_data ))
        end
        
        if status then

            client:set_active(status)
            client.username = username
            MainPipe:process(event)
        else
            return nil
        end

    end

    return message
end)

ServerPipe:add_middleware(function(message)
    local client = message.client
    local response = { events = {} }

    while not List.is_empty(client.response_queue) do
        table.insert( response.events, List.popleft( client.response_queue ) )
    end

    Proto.send_text( client.network, json.tostring(response) )

    return client
end)

return ServerPipe
