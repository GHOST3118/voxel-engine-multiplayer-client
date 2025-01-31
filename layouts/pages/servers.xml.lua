local config = require "config"
require "multiplayer/global"

local connectors = {

}

function on_open()
    local handshake = require "multiplayer:multiplayer/utils/handshake"
    local username = config.data.profiles.current.username
    for index, value in pairs(config.data.multiplayer.servers) do
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
        local ip = string.split(value[2], ":")[1]
        local port = tonumber(string.split(value[2], ":")[2]) or 25565

        handshake.make(ip, port, function(server)
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
    end
end

function connect_to(id)
    if connectors[id] then
        connectors[id]()
    end
end
