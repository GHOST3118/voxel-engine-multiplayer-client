
app.config_packs({"multiplayer"})
app.load_content()

menu.page = "servers"

app.sleep_until(function () return not world.is_open() end)
local function leave_to_menu()
    print("leaving to menu")
    if world.is_open() then
        app.close_world(false)
    else
        app.reset_content()
        menu:reset()
        menu.page = "main"
    end
end

gui_util.add_page_dispatcher(function(name, args)
    if name == "pause" then
        name = "client_pause"
    end
    return name, args
end)

local session = require "multiplayer:multiplayer/global"
local Client = require "multiplayer:multiplayer/client/client"

events.on("connect", function(username, host, port, packet)
    if world.is_open() then
        app.close_world(false)
        
    end
    if session.client then
        session.client:disconnect()
        session.client = nil
    end

    session.username = username
    session.client = Client.new( host, port )
    session.client.on_disconnect = function (packet)
        gui.alert("Server disconnected | reason: "..packet.reason, leave_to_menu)
        
    end
    session.client.on_connect = function (_packet)
        app.config_packs({"base", "multiplayer"})
        app.new_world("", packet.seed, "base:demo", 0)
        events.emit("connected", session)
        
    end
    session.client:connect()

    
end)


events.on("disconnect", leave_to_menu)



app.sleep_until(function() return session.client and session.client.network:alive() end)

while session.client and session.client.network:alive() do
    session.client:tick()
    app.tick()
end

-- if not world.is_open() then

--     leave_to_menu()
-- end