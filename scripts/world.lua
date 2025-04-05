require "multiplayer/global"
local console = require "multiplayer/console"

local data_buffer = require "lib/common/data_buffer"

events.on(PACK_ID .. ":connected", function(_session)

    -- print('перезаписывам Session.client. прежняя версия:')
    -- debug.print(Session.client)
    -- print('новая версия:')
    -- debug.print(_Session.client)
    -- Session.client = _Session.client
end)

events.on(PACK_ID..":disconnect", function ()
    Session.client = nil
end)

function on_world_tick()
    if not Session.client then
    end

    if Session.client then
        Session.client:world_tick()
    end

    if Session.server then
        Session.server:tick()
    end

    -- Пока побудет тут
    local pid = hud.get_player()
    local x, y, z = player.get_pos(pid)

    if y < 0 or y > 262 then
        y = math.clamp(y, 0, 262)
        player.set_pos(pid, x, y, z)
    end
end

local timer = 0
function on_player_tick(playerid, tps)
    if not Session.client then
    end

    if Session.client and playerid == Session.player_id then
        Session.client:player_tick(playerid, tps)
    end

    events.emit("minimap:update")
end

function on_world_quit()
    -- if Session.client then
    --     Session.client:disconnect()
    -- end

    if Session.server then
        Session.server:stop()
    end
end

function on_block_placed(blockid, x, y, z, playerid)

    if Session.client then
        if Session.player_id ~= playerid then return end
        local states = block.get_states(x, y, z)
        local rotation = block.get_rotation(x, y, z)

        Session.client:on_block_placed(blockid, x, y, z, states, rotation)
    end
end

function on_block_broken(blockid, x, y, z, playerid)
    if Session.client then
        if Session.player_id ~= playerid then return end
        Session.client:on_block_broken(blockid, x, y, z)
    end
end

function on_block_interact(blockid, x, y, z, playerid)
    if Session.client then
        if Session.player_id ~= playerid then return end
        local states = block.get_states(x, y, z)
        Session.client:on_block_interact(blockid, x, y, z, states)
    end
end

function on_chunk_present(x, z, is_loaded)
    if Session.client then
        Session.client:on_chunk_present(x, z, is_loaded)
    end
end
