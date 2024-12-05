local Pipeline = require "lib/pipeline"
local session = require "global"

local NetworkPipe = Pipeline.new()

NetworkPipe:add_middleware(function()
    if not session.server then
        return nil
    end
    local data = session.server.network:recieve()

    if data and pcall(function()
        json.parse(data)
    end) then
        return json.parse(data)
    end
    return nill
end)

NetworkPipe:add_middleware(function(data)
    local server_event = data

    if server_event then
        if server_event.ConnectionAccepted then
            console.log("Успешное подключение к миру. ClientId: " ..
                            server_event.ConnectionAccepted.client_id)
        elseif server_event.ConnectionRejected then
            console.log("Не удалось подключиться к миру. Причина: " ..
                            server_event.ConnectionRejected.reason)
            
            session.server.disconnect()
            session.server = nil
        end
    end
end)

return NetworkPipe
