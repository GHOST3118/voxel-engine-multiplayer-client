local Network = require "lib/network"
local ClientSynchronizer = require "multiplayer/client_synchronizer"

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
    self.network:connect( self.host, self.port, cb )
end

function Multiplayer:disconnect()
    self.network:disconnect()
end

function Multiplayer:world_tick()
    local data = self.network:recieve()

    if data then
        pcall(function ()
            local server_event = json.parse( data )
            
            self.client_sync:server_time( server_event.time )

            for index, event in ipairs(server_event.events) do
                self.client_sync:world_tick( event )
            end
        end)
    end
end

function Multiplayer:player_tick(playerid)
    
end

return Multiplayer