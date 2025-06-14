local config = require "config"
require "multiplayer/global"

local connectors = {}
local handshakes = {}
local servertable = {}

local function clear_handshakes()
    for _, hs in pairs(handshakes) do
        if hs.socket then
            hs.socket:close()
        end
    end
    handshakes = {}
end

events.on(PACK_ID..":success", function (index, username, ip, port, server)
    if server then
        connectors[index] = function()
            events.emit(PACK_ID..":connect", username, ip, port, server)
            menu.page="connecting"
        end

        assets.load_texture(server.favicon, index .. ".icon")
        document["serverstatus_"..index].text = "[#22ff22]Online"
        document["playersonline_"..index].text = server.online .. " / " .. server.max
        document["playersonline_"..index].tooltip = table.concat(server.friends_states, "\n")
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
    refresh_server_list()
end

function refresh_server_list()
    document.server_list:clear()
    connectors = {}
    clear_handshakes()
    
    local handshake = require "multiplayer:multiplayer/utils/handshake"
    local username = config.data.profiles.current.username
    
    if not config.data.multiplayer.servers then
        config.data.multiplayer.servers = {}
        config.write()
    end
    
    for index, value in pairs(config.data.multiplayer.servers) do
        if not value or (value and value == 0) then goto continue end
        
        -- проверяем
        if not value[1] or not value[2] then
            console.log("| [ERROR] Некорректные данные сервера с индексом " .. index)
            goto continue
        end
        
        -- иконку загружаем
        assets.load_texture(file.read_bytes('multiplayer:default_icon.png'), index .. ".icon")
        
        -- добавляем
        document.server_list:add(gui.template("server", {
            id = ""..index,
            server_name = value[1],
            server_status = "[#aaaaaa]Pending...",
            players_online = "",
            server_motd = "",
            onclick = "connect_to(" .. index .. ")",
            server_favicon = index .. ".icon",
        }))
        
        -- получаем адрес
        local server_parts = string.split(value[2], ":")
        if #server_parts < 2 then
            document["serverstatus_"..index].text = "[#ab0000]Invalid address"
            goto continue
        end
        
        local ip = server_parts[1]
        local port = tonumber(server_parts[2]) or 25565
        
        -- проверяем
        local hs = handshake.create(ip, port, function (server)
            events.emit(PACK_ID..":success", index, username, ip, port, server)
        end,
        function ()
            events.emit(PACK_ID..":failed", index, ip, port)
        end)
        
        handshakes[index] = hs
        ::continue::
    end
    
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
