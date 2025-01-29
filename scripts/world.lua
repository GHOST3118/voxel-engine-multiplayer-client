require "multiplayer/global"
local console = require "multiplayer/console"
local data_buffer = require "core:data_buffer"

events.on("connected", function(_session)
end)

events.on("disconnect", function ()
    session.client = nil
end)

function on_world_tick()
        session.client:world_tick()
    if not Session.client then
    end

    if Session.client then
        Session.client:world_tick()
    end

    if Session.server then
        Session.server:tick()
    end
end

local timer = 0
function on_player_tick(playerid, tps)
    if Session.client then
        Session.client:player_tick(playerid, tps)
    end

    events.emit("minimap:update")
end

function on_world_quit()
    -- if session.client then
    --     session.client:disconnect()
    -- end

    if Session.server then
        Session.server:stop()
    end
end

function on_block_placed(blockid, x, y, z, playerid)

    if Session.client then
        if Session.client.player_id ~= playerid then return end
        local states = block.get_states(x, y, z)
        Session.client:on_block_placed(blockid, x, y, z, states)
    end
end

function on_block_broken(blockid, x, y, z, playerid)
    if Session.client then
        if Session.client.player_id ~= playerid then return end
        Session.client:on_block_broken(blockid, x, y, z)
    end
end