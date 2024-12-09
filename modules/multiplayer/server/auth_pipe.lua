local Pipeline = require "lib/pipeline"
local Proto = require "multiplayer/proto/core"
local session = require "multiplayer/global"
local ConnectionMessage = require "multiplayer/messages/connection"

local AuthPipe = Pipeline.new()

local function unique_username(username)
    for index, client in ipairs(session.server.clients) do
        if client.username == username then
            return false
        else
            return true
        end
    end

    return true
end

AuthPipe:add_middleware(function(message)
    local client = message.__client
    local network = message.__network

    return message
end)

AuthPipe:add_middleware(function(message)
    local client = message.__client
    local network = message.__network

    if message.Connect then
        local hasUsername = message.Connect.username ~= nil
        local uniqueUsername = unique_username(message.Connect.username)
        local checkVersion = message.Connect.version == "0.25.3"
        local accept = hasUsername and uniqueUsername and checkVersion

        if accept then
            local client_id = math.random(1, 1000)
            local Accept = ConnectionMessage.ConnectionAccepted.new(client_id)
            Proto.send_text(network, Accept)
            return {true, client_id, message.Connect.username}
        else
            local Reject = ConnectionMessage.ConnectionRejected.new("unknown error")

            if not hasUsername then Reject = ConnectionMessage.ConnectionRejected.new("username has'nt be empty")
            elseif not uniqueUsername then Reject = ConnectionMessage.ConnectionRejected.new("username is exists")
            elseif not checkVersion then Reject = ConnectionMessage.ConnectionRejected.new("version not appreoved")
            end

            Proto.send_text(network, Reject)
            return {false}
        end
    end

    return {false}
end)

return AuthPipe
