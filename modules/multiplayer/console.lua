local session = require "multiplayer/global"
local Client = require "multiplayer/client/client"
local Server = require "multiplayer/server/server"
local Proto = require "multiplayer/proto/core"

console.add_command(
    "connect host:str port:int",
    "Connect to Server",
    function (args, kwargs)
        if not session.username then
            return console.log('Имя пользователя не задано.')
        end

        if session.client then
            session.client:disconnect()
            console.log('Закрытие подключения...')
        end

        session.client = Client.new( unpack(args) )
        session.client:connect()
    end
)

console.add_command(
    "c",
    "fast conn",
    function (args, kwargs)
        console.execute("connect localhost 3000")
    end
)

console.add_command(
    "cu username:str",
    "Change Username",
    function (args, kwargs)
        session.username = args[1]
        console.log('Имя изменнено на '..session.username)
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