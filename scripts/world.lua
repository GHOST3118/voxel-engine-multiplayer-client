local session = require "multiplayer/global"
local console = require "multiplayer/console"
local data_buffer = require "core:data_buffer"

events.on("connected", function(_session)
    session.client = _session.client
end)

function on_world_tick()
    if session.client then
        session.client:world_tick()
    end

    if session.server then
        session.server:tick()
    end
end

local timer = 0
function on_player_tick(playerid, tps)
    if session.client then
        session.client:player_tick(playerid, tps)
    end

    events.emit("minimap:update")
end

function on_world_quit()
    -- if session.client then
    --     session.client:disconnect()
    -- end

    if session.server then
        session.server:stop()
    end
end

function on_block_placed(blockid, x, y, z, playerid)

    if session.client then
        if session.client.player_id ~= playerid then return end
        local states = block.get_states(x, y, z)
        session.client:on_block_placed(blockid, x, y, z, states)
    end
end

function on_block_broken(blockid, x, y, z, playerid)
    if session.client then
        if session.client.player_id ~= playerid then return end
        session.client:on_block_broken(blockid, x, y, z)
    end
end