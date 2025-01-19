local session = require "multiplayer/global"
local console = require "multiplayer/console"
local protocol = require "lib/protocol"


local timer = 0
local socket
function on_world_tick()
    if session.client then
        session.client:world_tick()
    end

    if session.server then
        session.server:tick()
    end
end

function on_player_tick(playerid, tps)
    if session.client then
        session.client:player_tick(playerid, tps)
    end
end

function on_world_quit()
    if session.client then
        session.client:disconnect()
    end

    if session.server then
        session.server:stop()
    end
end