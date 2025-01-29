local protocol = require "lib/protocol"
require "multiplayer/global"

local LoginHandlers = {}

LoginHandlers.on_event = function (client)
    return function (packet)
        debug.print(packet)
        if packet.packet_type == protocol.ServerMsg.JoinSuccess then
            client.on_connect( packet )
            console.log("Подключение успешно! время: "..packet.game_time)
            -- world.set_day_time_speed(0)
            Session.client.entity_id = packet.entity_id
            print("Connected to server!")
            return protocol.States.Active
        else
            local str = ""
            if packet.packet_type == protocol.ServerMsg.Disconnect then
                str = "Сервер отказал в подключении."
                if packet.reason then str = str .. " Причина: " .. packet.reason end
                
            else
                str = "Сервер отправил какую-то ерунду вместо ожидаемых данных. Соединение разорвано."
            end
            console.log(str)
            client.on_disconnect( packet )
            -- самоуничтожаемся!
            Session.client:disconnect()
            
            return nil
        end
    end
end

LoginHandlers.on_enter = function (client)
    return function ()
        local packet = protocol.create_databuffer()
        packet:put_packet(protocol.build_packet("client", protocol.ClientMsg.HandShake, "0.26.0", protocol.data.version, protocol.States.Login))
        client.network:send(packet.bytes)

        packet = protocol.create_databuffer()
        packet:put_packet(protocol.build_packet("client", protocol.ClientMsg.JoinGame, Session.username))
        client.network:send(packet.bytes)
    end
end

return LoginHandlers