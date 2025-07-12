local protocol = require "lib/protocol"
local hash = require "lib/common/hash"
require "multiplayer/global"

local LoginHandlers = {}

LoginHandlers.on_event = function(client)
    return function(packet)
        if packet.packet_type == protocol.ServerMsg.JoinSuccess then
            client.on_connect(packet)
            console.log("Подключение успешно!")
            Session.client.entity_id = packet.entity_id
            return protocol.States.Active
        elseif packet.packet_type == protocol.ServerMsg.PacksList then
            local packs = packet.packs
            local pack_available = pack.get_available()
            local pack_installed = pack.get_installed()
            local hashes = {}

            for i = #packs, 1, -1 do
                if not table.has(pack_available, packs[i]) then
                    table.remove(packs, i)
                end
            end

            _G["$APP"].reset_content()
            _G["$APP"].config_packs({ "multiplayer" })
            _G["$APP"].reconfig_packs(packs, {})
            _G["$APP"].load_content()

            for i, pack in ipairs(packs) do
                table.insert(hashes, pack)
                table.insert(hashes, hash.hash_mods({ pack }))
            end

            CONTENT_PACKS = packs

            packet = protocol.create_databuffer()
            packet:put_packet(protocol.build_packet("client", protocol.ClientMsg.PacksHashes, hashes))
            client.network:send(packet.bytes)
        else
            local str = ""
            if packet.packet_type == protocol.ServerMsg.Disconnect then
                str = "Сервер отказал в подключении."
                if packet.reason then str = str .. " Причина: " .. packet.reason end
            else
                str = "Сервер отправил какую-то ерунду вместо ожидаемых данных. Соединение разорвано."
            end
            console.log(str)
            client.on_disconnect(packet)
            -- самоуничтожаемся!
            Session.client:disconnect()

            return nil
        end
    end
end

LoginHandlers.on_enter = function(client)
    return function()
        local packet = protocol.create_databuffer()
        local major, minor = _G["$APP"].get_version()
        local engine_version = string.format("%s.%s.0", major, minor)
        packet:put_packet(protocol.build_packet("client", protocol.ClientMsg.HandShake, engine_version, protocol.data.version, {},
            protocol.States.Login))
        client.network:send(packet.bytes)

        ---

        packet = protocol.create_databuffer()
        packet:put_packet(protocol.build_packet("client", protocol.ClientMsg.JoinGame, Session.username))
        client.network:send(packet.bytes)
    end
end

return LoginHandlers
