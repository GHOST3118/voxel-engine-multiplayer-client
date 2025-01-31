require "multiplayer/global"
local Client = require "multiplayer/client/client"
local Server = require "multiplayer/server/server"
local protocol = require "lib/protocol"
local client_queue = require "multiplayer/client/client_queue"
local List = require "lib/common/list"

console.add_command(
    "chat message:str",
    "Send message",
    function (args, kwargs)
        if Session.client then
            local buffer = protocol.create_databuffer()
            buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.ChatMessage, args[1]))
            Session.client.network:send(buffer.bytes)
        elseif Session.server then
            local msg = "[HOST] "..args[1]
            -- console.log("| "..msg)
            for _, client in ipairs(Session.server.clients) do
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
console.submit = function (command)
    local name, args = command:match("^(%S+)%s*(.*)$")

    if name == "chat" then
        -- console.log(  )
        console.execute(command)
    else
        console.execute("chat '."..command.."'")
    end
end