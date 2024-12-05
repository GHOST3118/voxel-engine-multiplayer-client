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
    self.network:connect( self.host, self.port, function (status)
        if status then
            local connect_message = {
                Connect = { username = "TestUname", version = "0.25.2" },
            }

            self.network:send( json.tostring( connect_message ) )
            cb(status)
        end
    end )
    
end

function Multiplayer:disconnect()
    self.network:disconnect()
end

function Multiplayer:world_tick()
    local data = self.network:recieve()

    if data then
        pcall(function ()
            local server_event = json.parse( data )
            print(data)
            if server_event then
                if server_event.ConnectionAccepted then
                    console.log( "Успешное подключение к миру. ClientId: "..server_event.ConnectionAccepted.client_id )
                elseif server_event.ConnectionRejected then
                    console.log( "Не удалось подключиться к миру. Причина: "..server_event.ConnectionRejected.reason )
                end
            end
        end)
    end
end

function Multiplayer:player_tick(playerid)
    
end

return Multiplayer