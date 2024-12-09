local CommandMessage = {}

CommandMessage.StatusRequest = {}
function CommandMessage.StatusRequest.new()
    local schema = {
        Status = true
    }

    return json.tostring( schema )
end

CommandMessage.StatusResponse = {}
function CommandMessage.StatusResponse.new()
    local schema = {
        Status = "[server] connected"
    }

    return json.tostring( schema )
end

CommandMessage.PlayersRequest = {}
function CommandMessage.PlayersRequest.new()
    local schema = {
        Players = true
    }

    return json.tostring( schema )
end

CommandMessage.PlayersResponse = {}
function CommandMessage.PlayersResponse.new( clients )
    local players = {}

    for index, client in ipairs(clients) do
        table.insert( players, { username = client.username, client_id = client.client_id } )
    end

    local schema = {
        Players = players
    }

    return json.tostring( schema )
end

return CommandMessage