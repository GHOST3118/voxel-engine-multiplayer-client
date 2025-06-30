app.config_packs({ "multiplayer" })
app.load_content()

_G["$APP"] = app
_G['$Neutron'] = nil

function _G.start_require(path)
    if not string.find(path, ':') then
        local prefix, _ = parse_path(debug.getinfo(2).source)
        return start_require(prefix .. ':' .. path)
    end

    local old_path = path
    local prefix, file = parse_path(path)
    path = prefix .. ":modules/" .. file .. ".lua"

    if not _G["/$p"] then
        return require(old_path)
    end

    if not _G["/$p"][path] then
        return require(old_path)
    end

    return _G["/$p"][path]
end

local set_pos = player["set_pos"]

player.set_pos = function (pid, x, y, z)

    local entity = entities.get(player.get_entity(pid))

    if entity then
        entity.rigidbody:set_enabled(true)
        local transform, rigidbody = entity.transform, entity.rigidbody
        rigidbody:set_vel({0, 0, 0})
        local current_pos = transform:get_pos()
        local target_pos = {x, y, z}
        local direction = vec3.sub(target_pos, current_pos)
        local distance = vec3.length(direction)

        if distance > 10 or distance < 0.01 then
            transform:set_pos(target_pos)
            rigidbody:set_vel({0, 0, 0})
        elseif rigidbody then
            local time_to_reach = 0.1
            local velocity = vec3.mul(vec3.normalize(direction), distance / time_to_reach)
            rigidbody:set_vel(velocity)
        end
    else
        set_pos(pid, x, y, z)
    end
end

function math.bit_length(num)
    if num == 0 then
        return 0
    end
    local count = 0
    while num > 0 do
        count = count + 1
        num = math.floor(num / 2)
    end
    return count
end

function table.rep(tbl, elem, rep_count)
    for i=1, rep_count do
        table.insert(tbl, table.deep_copy(elem))
    end

    return tbl
end

_G["/$p"] = table.copy(package.loaded)

menu.page = "servers"

-- Sleep until the world is closed
app.sleep_until(function() return not world.is_open() end)

-- Disconnect from the server
local function disconnect()
    if Session.client then
        Session.client:disconnect()
        Session.client = nil
    end
end

-- Leave to the menu
local function leave_to_menu()
    if world.is_open() then
        app.close_world(false)
    end
    _G['$Neutron'] = nil

    app.reset_content()
    menu:reset()
    menu.page = "main"

    disconnect()
end

-- Add a page dispatcher to change the page name
gui_util.add_page_dispatcher(function(name, args)
    if name == "pause" then
        name = "client_pause"
    end

    return name, args
end)

require "multiplayer:multiplayer/global"
local Client = require "multiplayer:multiplayer/client/client"
local chunks_distance = 255

-- ----------------------------------------------
-- EVENTS REGISTER START
-- ----------------------------------------------
events.on(ON_CONNECT, function(username, host, port, packet)
    if world.is_open() then
        app.close_world(false)
        disconnect()
    end

    Session.username = username
    Session.client = Client.new(host, port)
    Session.client.on_disconnect = function(_packet)
        _packet.reason = _packet.reason or "No reason"
        gui.alert("Server disconnected | reason: " .. _packet.reason, leave_to_menu)
    end
    Session.client.on_connect = function(_packet)
        _G['$Neutron'] = "client"
        _G['$Multiplayer'] = {
            side = "client",
            api_reference = {
                name = "Neutron",
                version = 1
            }
        }
        chunks_distance = _packet.chunks_loading_distance
        app.new_world("", "41530140565755", "multiplayer:void", _packet.entity_id)

        for _, rule in ipairs(_packet.rules) do
            rules.set(rule[1], rule[2])
        end

        Session.player_id = _packet.entity_id

        events.emit(PACK_ID .. ":connected", Session)
    end
    Session.client:connect()
end)

events.on(ON_DISCONNECT, leave_to_menu)
-- ----------------------------------------------
-- EVENTS REGISTER END
-- ----------------------------------------------

local config = require "multiplayer:config"
local handshake = require "multiplayer:multiplayer/utils/handshake"

local handshakes = {}
local proccess_handshakes = coroutine.create(function()
    for index, value in pairs(config.data.multiplayer.servers) do
        local ip = string.split(value[2], ":")[1]
        local port = tonumber(string.split(value[2], ":")[2]) or 25565

        local hs = handshake.create(ip, port, function(server)
                events.emit(PACK_ID .. ":success", index, config.data.profiles.current.username, ip, port, server)
            end,
            function()
                events.emit(PACK_ID .. ":failed", index, ip, port)
            end)

        handshakes[index] = hs
        coroutine.yield()
    end
end)

while not world.is_open() do
    if coroutine.status(proccess_handshakes) == "suspended" then
        coroutine.resume(proccess_handshakes)
    end

    for index, hs in pairs(handshakes) do
        hs:tick()
    end

    if Session.client then
        Session.client:await_join()
    end

    if _G['$Neutron'] or _G['$Multiplayer'] then
        _G['$Neutron'] = nil
        _G['$Multiplayer'] = nil
    end

    app.tick()
end

app.sleep_until(function() return Session.client and Session.client.network:alive() and world.is_open() end)
-- Client Loop
while Session.client do
    Session.client:tick()
    if app.get_setting("chunks.load-distance") > chunks_distance then
        app.set_setting("chunks.load-distance", chunks_distance)
    end
    app.tick()
end

leave_to_menu()
