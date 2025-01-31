
app.config_packs({"multiplayer"})
app.load_content()

menu.page = "servers"

app.sleep_until(function () return not world.is_open() end)
local function leave_to_menu()
    if world.is_open() then
        app.close_world(false)
    end
    app.reset_content()
    menu:reset()
    menu.page = "main"
    Session.client:disconnect()
    Session.client = nil
end

gui_util.add_page_dispatcher(function(name, args)
    if name == "pause" then
        name = "client_pause"
    end
    return name, args
end)

require "multiplayer:multiplayer/global"
local Client = require "multiplayer:multiplayer/client/client"

events.on(PACK_ID .. ":connect", function(username, host, port, packet)
    if world.is_open() then
        app.close_world(false)

        if Session.client then
            Session.client:disconnect()
            Session.client = nil
        end
    end

    Session.username = username
    Session.client = Client.new( host, port )
    Session.client.on_disconnect = function (_packet)
        gui.alert("Server disconnected | reason: ".._packet.reason, leave_to_menu)

    end
    Session.client.on_connect = function (_packet)

        Session.player_id = _packet.entity_id
        app.config_packs({"base", "multiplayer"})
        app.new_world("", packet.seed, "base:demo", _packet.entity_id)
        events.emit(PACK_ID .. ":connected", Session)

    end
    Session.client:connect()
end)


events.on(PACK_ID..":disconnect", leave_to_menu)

while not world.is_open() do
    
    if Session.client then
        Session.client:await_join()
    end
    
    app.tick()
end

app.sleep_until(function() return Session.client and Session.client.network:alive() and world.is_open() end)

while Session.client and Session.client.network:alive() do
    Session.client:tick()
    app.tick()
end

-- if not world.is_open() then

--     leave_to_menu()
-- end