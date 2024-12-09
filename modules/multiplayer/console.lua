local session = require "multiplayer/global"
local Multiplayer = require "multiplayer/client/client"
local Server = require "multiplayer/server/server"
local NetworkPipe = require "multiplayer/client/network_pipe"
local Proto = require "multiplayer/proto/core"

console.add_command(
    "connect host:str port:int",
    "Connect to Server",
    function (args, kwargs)
        if session.client then
            session.client:disconnect()
            console.log('Закрытие подключения...')
        end

        session.client = Multiplayer.new( unpack(args) )
        session.client:connect(function (status)
            if status then
                console.log('Идет подключение...')
            else
                console.log('Не удалось подключиться к миру')
            end
        end)
    end
)

console.add_command(
    "c",
    "Connect to Server",
    function (args, kwargs)
        if session.client then
            session.client:disconnect()
            console.log('Закрытие подключения...')
        end

        session.client = Multiplayer.new( "localhost", 3000 )
        session.client:connect(function (status)
            if status then
                console.log('Идет подключение...')
            else
                console.log('Не удалось подключиться к миру')
            end
        end)
    end
)

NetworkPipe:add_middleware(function (server_event)
    if server_event.Status then
        console.log( server_event.Status )
    end

    return server_event
end)

console.add_command(
    "server_info",
    "Server Info",
    function (args, kwargs)
        if session.client then
            Proto.send_text(session.client.network, json.tostring({ Status = true }))
        end
        
    end
)

NetworkPipe:add_middleware(function (server_event)
    if server_event.Players then
        for index, player in ipairs(server_event.Players) do
            console.log( "["..index.."] "..player.username )
        end
    end

    return server_event
end)

console.add_command(
    "players",
    "Server Players",
    function (args, kwargs)
        if session.client then
            Proto.send_text(session.client.network, json.tostring({ Players = true }))
        end
        
    end
)

console.add_command(
    "cu username:str",
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
        if session.client then
            session.client:disconnect()
        end
    end
)

console.add_command(
    "serve",
    "Server open",
    function (args, kwargs)
        if session.server then
            console.log('Сервер уже запущен')
        elseif session.client then
            console.log('Невозможно запустить сервер пока вы подключены к другому серверу')
        else
            session.server = Server.new(3000)
            session.server:serve()
        end
    end
)

console.add_command(
    "stop",
    "Server stop",
    function (args, kwargs)
        if session.server then
            console.log('Сервер не запущен')
        else
            session.server:stop()
            session.server = nil
        end
    end
)