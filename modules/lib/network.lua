local socketlib = require "lib/socketlib"

local Network = {}
Network.__index = Network

local P_LENGTH = 1024

function Network.new()
    local self = setmetatable({}, Network)

    self.socket = nil

    return self
end

function Network:connect(host, port, cb)

    socketlib.connect(host, port, function(sock)
        self.socket = sock
        cb(true)
    end,
    function (e)
        print(e)
        cb(false)
    end)
end

function Network:disconnect()
    if self.socket then
        socketlib.close_socket( self.socket )
        self.socket = nil
    end
end

function Network:send(data)
    if self.socket and self.socket:is_alive() then
        socketlib.send_text( self.socket, data )
    end
end

function Network:recieve()

    if self.socket and self.socket:is_alive() then
        return socketlib.receive_text( self.socket, P_LENGTH)
    end
end

return Network