local socketlib = require "lib/socketlib"
local Proto = require "multiplayer/proto/core"
local Network = require "lib/network"
local List = require "lib/common/list"
local Player = require "multiplayer/server/classes/player"

local ServerPipe = require "multiplayer/server/server_pipe"

local Server = {}
Server.__index = Server

function Server.new(port)
    local self = setmetatable({}, Server)

    self.port = port

    self.clients = {}
    self.server_socket = nil

    return self
end

function Server:serve()
    self.server_socket = socketlib.create_server(self.port, function(client_socket)
        local network = Network.new( client_socket )
        local client = Player.new(false, network)

        table.insert(self.clients, client)
    end)
end

function Server:queue_response(event)
    for index, client in ipairs(self.clients) do
        List.pushright(client.response_queue, event)
    end
end

function Server:stop()
    self.server_socket:close()
end

function Server:tick()
    for index, client in ipairs(self.clients) do
        local socket = client.network.socket
        if socket and socket:is_alive() then

            ServerPipe:process(client)
        else
            table.remove_value(self.clients, client)
        end
    end
end

return Server
