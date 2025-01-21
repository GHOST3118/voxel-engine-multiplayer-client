local protocol = require "lib/protocol"
local session = require "multiplayer/global"

local LoginHandlers = {}

LoginHandlers.on_event = function (client)
    return function (packet)

        if packet.packet_type == protocol.ServerMsg.JoinSuccess then
            console.log("Подключение успешно! время: "..packet.game_time)
            world.set_day_time_speed(0)
            session.client.entity_id = packet.entity_id
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
            -- самоуничтожаемся!
            session.client:disconnect()
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
        packet:put_packet(protocol.build_packet("client", protocol.ClientMsg.JoinGame, session.username))
        client.network:send(packet.bytes)
    end
end

return LoginHandlers