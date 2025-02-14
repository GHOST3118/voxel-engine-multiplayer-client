local config = require "config"
require "multiplayer/global"

local connectors = {

}

local servertable = {}

events.on(PACK_ID..":success", function (index, username, ip, port, server)
    if server then
        connectors[index] = function()
            events.emit(PACK_ID..":connect", username, ip, port, server)
            menu.page="connecting"
        end

        assets.load_texture(server.favicon, index .. ".icon")
        document["serverstatus_"..index].text = "[#22ff22]Online"
        document["playersonline_"..index].text = server.online .. " / " .. server.max
        document["playersonline_"..index].tooltip = table.concat(server.players, "\n")
        -- не удалось понять почему не работает tooltip.
        -- возможно потому что это элемент списка?
        document["servermotd_"..index].text = server.name
    else
        document["serverstatus_"..index].text = "[#ff2222]Offline"
        document["playersonline_"..index].text = ""
        document["servermotd_"..index].text = "[#ff2222]Can't reach the server"
    end
end)

events.on(PACK_ID..":failed", function (index, ip, port)
    -- будем считать, что обратились туда-не-знаю-куда за тем-не-знаю-чем
    document["serverstatus_"..index].text = "[#ff2222]Error"
    document["playersonline_"..index].text = ""
    document["servermotd_"..index].text = "[#ff2222]Unknown host"
    print("Handshake error. Host address: \""..ip..":"..port.."\"")
end)

function on_open()
    local handshake = require "multiplayer:multiplayer/utils/handshake"
    local username = config.data.profiles.current.username
    for index, value in pairs(config.data.multiplayer.servers) do
        if not value or (value and value == 0) then goto continue end
        assets.load_texture(file.read_bytes('multiplayer:default_icon.png'), index .. ".icon")
        document.server_list:add(gui.template("server", {
            id = ""..index,
            server_name = value[1],
            server_status = "[#aaaaaa]Pending...",
            players_online = "",
            server_motd = "",
            onclick = "connect_to(" .. index .. ")",
            server_favicon = index .. ".icon",
        }))
        ::continue::
    end

    

    -- таблица хранит в себе список серверов для возможности их удаления
    servertable = table.copy(config.data.multiplayer.servers)
end

function remove_server(id)
    document["serverlist_"..id]:destruct()
    servertable[id] = 0
    -- дополнительная таблица, которую мы скукожим и запишем в конфиг
    local tmptable = table.copy(servertable)
    while table.has(tmptable, 0) do
        table.remove_value(tmptable, 0)
    end
    config.data.multiplayer.servers = table.copy(tmptable)
    config.write()
end

function connect_to(id)
    if connectors[id] then
        connectors[id]()
    end
end
