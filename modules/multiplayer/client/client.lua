local Network = require "lib/network"
local NetworkPipe = require "multiplayer/client/network_pipe"
local session = require "multiplayer/global"

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
        -- pass
    end )
end

function Client:disconnect()
    self.network:disconnect()
    session.client = nil
end

function Client:world_tick()
    NetworkPipe:process()
end

function Client:player_tick(playerid, tps)
    -- pass
end

return Client