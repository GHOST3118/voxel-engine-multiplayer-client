local Network = require "lib/network"
local ClientSynchronizer = require "multiplayer/client_synchronizer"
local NetworkPipe = require "multiplayer/network_pipe"
local session = require "global"

local Multiplayer = {}
Multiplayer.__index = Multiplayer

function Multiplayer.new(host, port)
    local self = setmetatable({}, Multiplayer)

    self.host = host
    self.port = port

    self.players = {}
    self.network = Network.new()

    self.client_sync = ClientSynchronizer.new( self.network )

    return self
end

function Multiplayer:connect(cb)
    self.network:connect( self.host, self.port, function (status)
        if status then
            local connect_message = {
                Connect = { username = session.uname, version = "0.25.2" },
            }

            self.network:send( json.tostring( connect_message ) )
            cb(status)
        end
    end )
    
end

function Multiplayer:disconnect()
    self.network:disconnect()
    session.server = nil

end

function Multiplayer:world_tick()
    NetworkPipe:process()
end

function Multiplayer:player_tick(playerid)
    
end

return Multiplayer