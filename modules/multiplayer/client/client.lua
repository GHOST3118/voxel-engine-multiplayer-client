local Network = require "lib/network"
local ClientSynchronizer = require "multiplayer/client/client_synchronizer"
local NetworkPipe = require "multiplayer/client/network_pipe"
local PlayerPipe = require "multiplayer/client/player_pipe"
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

    self.client_sync = ClientSynchronizer.new( self.network )

    return self
end

function Client:connect(cb)
    self.network:connect( self.host, self.port, function (status)
        if status then
            local connect_message = ConnectionMessage.Connect.new(session.uname, "0.25.3")

            Proto.send_text( self.network, connect_message )
            cb(status)

            NetworkPipe:add_middleware(function (data)
                self.client_sync:handle_player( data )
            end)
        end
    end )
    
end

function Client:disconnect()
    self.network:disconnect()
    session.client = nil

end

function Client:world_tick()
    NetworkPipe:process()
end

function Client:player_tick(playerid)
    PlayerPipe:process( playerid )
    
end

return Client