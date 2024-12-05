local socketlib = require "lib/socketlib"
local session = require "global"
local command = require "multiplayer/console"

function on_world_tick()
    if session.server then
        session.server:world_tick()
    end
end

function on_block_placed(blockid, x, y, z, playerid)
    if session.server then
        session.server.client_sync:on_block_placed_handler(blockid, x, y, z, playerid)
    end
end

function on_block_replaced(blockid, x, y, z, playerid)
    if session.server then
        session.server.client_sync:on_block_replaced_handler(blockid, x, y, z, playerid)
    end
end

function on_block_broken(blockid, x, y, z, playerid)
    if session.server then
        session.server.client_sync:on_block_broken_handler(blockid, x, y, z, playerid)
    end
end