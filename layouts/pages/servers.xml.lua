

local connectors = {

}

function on_open()
    local handshake = require "multiplayer:multiplayer/utils/handshake"
    local path = pack.shared_file("multiplayer", "local_profile.toml")
    if file.exists( path ) then
        local profile = toml.parse( file.read(path) )

        debug.print( profile )
    end

    handshake.make("localhost", 25565, function ( server )
        if server then
            connectors[1] = function ()
                events.emit(PACK_ID .. "connect", "ghosta", "localhost", 25565, server)
            end

            assets.load_texture(server.favicon, server.name..".icon")

            document.server_list:add( gui.template("server", {
                server_name = server.name,
                server_status = "[#00aa00]online",
                onclick = "connect_to(1)",
                server_favicon = server.name..".icon",
                players_online = server.online.." / "..server.max
            }) )

        else
            document.server_list:add( gui.template("server", {
                server_name = "[#aa0000]Failed to get status",
                server_status = "[#aa0000]offline",
            }) )
        end
        
    end)
    
end

function connect_to(id)
    if connectors[id] then
        
        connectors[id]()
    end
end