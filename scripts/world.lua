local SocketFramework = require "socketlib"

history = session.get_entry("commands_history")

local client = nil
local socket = nil

console.add_command(
    "socket-test message:str",
    "Socket Send Test Message",
    function (args, kwargs)
        if socket ~= nil then
            socket:send( player.get_name().."<%>"..unpack(args) )
        end
    end
)

function on_world_open()
    client = SocketFramework.Socket.new("localhost", 3000)
    client:connect(function(sock)
        print("Connected to server.")
        socket = sock
    end)
end

function on_world_tick()
    SocketFramework.update()
    socket:receive(1024, function(data)
        print("Received from server:", data)

        local e = json.parse( data )
        if e and e.ev_type == "BLOCK_PLACE" then
            block.set( e.x, e.y, e.z, e.blockid, 0 )
        end
    end)
end

function on_block_placed(blockid, x, y, z, playerid)
    local data = {}
        data.ev_type = "BLOCK_PLACE"
        data.blockid = blockid
        data.x = x
        data.y = y
        data.z = z
        data.playerid = playerid

    socket:send( json.tostring(data) )
end