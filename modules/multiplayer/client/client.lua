local Network = require "lib/network"
local uuid = require "lib/uuid"
local List = require "lib/common/list"

local ClientQueue = require "multiplayer/client/client_queue"
local NetworkPipe = require "multiplayer/client/network_pipe"
local ConnectionMessage = require "multiplayer/messages/connection"
local session = require "multiplayer/global"

local Proto = require "multiplayer/proto/core"

local Client = {}
Client.__index = Client

function Client.new(host, port)
    local self = setmetatable({}, Client)

    self.host = host
    self.port = port

    self.players = {}
    self.network = Network.new()

    self.handlers = {}

    return self
end

function Client:connect()
    self.network:connect( self.host, self.port, function (status)
        if status then
            local connect_message = ConnectionMessage.Connect.new(session.username, "0.25.3")

            self:queue_request( connect_message, function (event)
                if event.ConnectionAccepted then
                    console.log( "Успешное подключение к миру" )
                end
            end)
        end
    end )
    
end

function Client:queue_request( payload, cb )
    local request_uuid = uuid.getUUID()

    List.pushright( ClientQueue, {
        request_uuid = request_uuid,
        payload = payload
    } )
    self.handlers[ request_uuid ] = cb
end

function Client:disconnect()
    self.network:disconnect()
    session.client = nil

end

function Client:world_tick()
    NetworkPipe:process()
end

function Client:player_tick(playerid)
    
end

return Client