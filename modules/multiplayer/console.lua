local session = require "global"
local Multiplayer = require "multiplayer"

console.add_command(
    "connect host:str port:int",
    "Connect to Server",
    function (args, kwargs)
        session.server = Multiplayer.new( unpack(args) )
        session.server:connect(function (status)
            if status then
                console.log('Идет подключение...')
            else
                console.log('Не удалось подключиться к миру')
            end
        end)
    end
)

console.add_command(
    "disconnect",
    "Close connection with Server",
    function (args, kwargs)
        if session.server then
            session.server:disconnect()
        end
    end
)