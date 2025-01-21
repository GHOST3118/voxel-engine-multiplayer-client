local session = require "multiplayer/global"
local Client = require "multiplayer/client/client"
local Server = require "multiplayer/server/server"
local protocol = require "lib/protocol"
local client_queue = require "multiplayer/client/client_queue"
local List = require "lib/common/list"

local function push_packet(list, packet)
    local buffer = protocol.create_databuffer()
    buffer:put_packet(packet)
    List.pushright(list, buffer.bytes)
end

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
    "Connect to dev server",
    function (args, kwargs)
        console.execute("connect localhost 25565")
    end
)

console.add_command(
    "execute script:str",
    "Connect to dev server",
    function (args, kwargs)
        console.execute(unpack(args))
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

console.add_command(
    "chat message:str",
    "Send message",
    function (args, kwargs)
        if session.client then
            local buffer = protocol.create_databuffer()
            buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.ChatMessage, args[1]))
            session.client.network:send(buffer.bytes)
        elseif session.server then
            local msg = "[HOST] "..args[1]
            console.log("| "..msg)
            for _, client in ipairs(session.server.clients) do
                if client.network.socket and client.network.socket:is_alive() and client.active then
                    local buffer = protocol.create_databuffer()
                    buffer:put_packet(protocol.build_packet("server", protocol.ServerMsg.ChatMessage, 0, msg, 0))
                    client.network.socket:send(buffer.bytes)
                end
            end
        else
            console.log('Невозможно отправить сообщение, пока вы не являетесь клиентом или хостом.')
        end
    end
)