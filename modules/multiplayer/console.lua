local session = require "global"
local Multiplayer = require "multiplayer"
local NetworkPipe = require "multiplayer/network_pipe"

console.add_command(
    "connect host:str port:int",
    "Connect to Server",
    function (args, kwargs)
        if session.server then
            session.server:disconnect()
            console.log('Закрытие подключения...')
        end

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
    "server_info",
    "Server Info",
    function (args, kwargs)
        if session.server then
            session.server.network:send( json.tostring({ Status = true }) )
            NetworkPipe:add_middleware(function (server_event)
                if server_event.Status then
                    console.log( server_event.Status )
                end

                return server_event
            end)
        end
        
    end
)

console.add_command(
    "players",
    "Server Players",
    function (args, kwargs)
        if session.server then
            session.server.network:send( json.tostring({ Players = true }) )
            NetworkPipe:add_middleware(function (server_event)
                print( json.tostring(server_event) )
                if server_event.Players then
                    for index, player in ipairs(server_event.Players) do
                        console.log( player.username )
                    end
                end

                return server_event
            end)
        end
        
    end
)

console.add_command(
    "change-username username:str",
    "Change Username",
    function (args, kwargs)
        session.uname = args[1]
        console.log('Имя изменнено на '..session.uname)
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