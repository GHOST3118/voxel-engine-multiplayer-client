local session = require "multiplayer/global"
local Client = require "multiplayer/client/client"
local Server = require "multiplayer/server/server"
local Proto = require "multiplayer/proto/core"

console.add_command(
    "connect host:str port:int",
    "Connect to Server",
    function (args, kwargs)
        if not session.username then
            return console.log('Имя пользователя не задано, задайте с помощью команды "cu никнейм"!')
        end

        if session.client then
            session.client:disconnect()
            console.log('Закрытие подключения...')
        end

        console.log('Подключение...')
        session.client = Client.new( unpack(args) )
        session.client:connect()
    end
)

console.add_command(
    "c",
    "Connect to localhost:3000",
    function (args, kwargs)
        console.execute("connect localhost 3000")
    end
)

console.add_command(
    "server_info",
    "Server Info",
    function (args, kwargs)
        if session.client then
            session.client:queue_request({ Status = true }, function (event)
                console.log(event.Status)
            end)
        end
    end
)

console.add_command(
    "list",
    "Print player list",
    function (args, kwargs)
        if session.client then
            session.client:queue_request({ Players = true }, function (event)
                if event.Players then
                    for index, player in ipairs(event.Players) do
                        console.log( "["..(index).."] "..player.username )
                    end
                end
            end)
        end
    end
)

console.add_command(
    "cu username:str",
    "Change Username",
    function (args, kwargs)
        session.username = args[1]
        console.log('Имя изменнено на "'..session.username..'"')
    end
)

console.add_command(
    "disconnect",
    "Close connection with Server",
    function (args, kwargs)
        if session.client then
            session.client:disconnect()
            console.log('Закрытие подключения...')
        end
    end
)

console.add_command(
    "serve",
    "Open server",
    function (args, kwargs)
        if session.server then
            console.log('Сервер уже запущен!')
        elseif session.client then
            console.log('Невозможно запустить сервер, пока вы подключены к другому серверу')
        else
            local port = 3000
            session.server = Server.new(port)
            session.server:serve()
            console.log('Сервер открыт, слушаем порт '..port)
        end
    end
)

console.add_command(
    "stop",
    "Close server",
    function (args, kwargs)
        if session.server then
            console.log('Сервер ещё не запущен!')
        else
            session.server:stop()
            session.server = nil
            console.log('Сервер был остановлен')
        end
    end
)