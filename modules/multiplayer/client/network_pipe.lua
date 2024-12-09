local Pipeline = require "lib/pipeline"
local session = require "multiplayer/global"
local Proto = require "multiplayer/proto/core"

local NetworkPipe = Pipeline.new()

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
    local server_event = data

    if server_event then
        if server_event.ConnectionAccepted then
            console.log("Успешное подключение к миру. ClientId: " ..
                            server_event.ConnectionAccepted.client_id)
            session.client_id = server_event.ConnectionAccepted.client_id
        elseif server_event.ConnectionRejected then
            console.log("Не удалось подключиться к миру. Причина: " ..
                            server_event.ConnectionRejected.reason)
            Proto.send_text( session.client.network, json.tostring({ Close = true }) )
        end

        return server_event
    end
end)

return NetworkPipe
