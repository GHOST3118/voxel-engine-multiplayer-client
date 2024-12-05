local NetworkData = require "network_data"

local ClientSynchronizer = {}
ClientSynchronizer.__index = ClientSynchronizer

function ClientSynchronizer.new( network )
    local self = setmetatable({}, ClientSynchronizer)

    self.network = network

    return self
end

function ClientSynchronizer:create_block_event( type, x, y, z, blockid, state, playerid, data )
    local schema = {
        playerid = playerid,
        blockid = blockid,
        position = {
            x = x, y = y, z = z
        },
        event_type = type,
        state = state or 0,
        player_name = data.player_name or "Unknown"
    }

    local event = NetworkData.new( schema )
    self.network:send( json.tostring( event ) )
end

function ClientSynchronizer:server_time( time )
    world.set_day_time( time )
end

function ClientSynchronizer:on_block_placed_event(blockid, x, y, z, playerid, state)
    block.set(x, y, z, blockid, state or 0)
end

function ClientSynchronizer:on_block_replaced_event(blockid, x, y, z, playerid, state)
    block.set(x, y, z, blockid, state or 0)
end

function ClientSynchronizer:on_block_broken_event(x, y, z, playerid)
    block.set(x, y, z, 0)
end

function ClientSynchronizer:world_tick( event )
    if event.event_type == 1 then
        self:on_block_placed_event(
            event.blockid,
            event.position.x,
            event.position.y,
            event.position.z,
            event.playerid,
            event.state or 0
        )
    elseif event.event_type == 2 then
        self:on_block_broken_event(
            event.position.x,
            event.position.y,
            event.position.z,
            event.playerid
        )
    end
end

function ClientSynchronizer:on_block_placed_handler(blockid, x, y, z, playerid)
    local state = block.get_states(x, y, z)
    self:create_block_event(1, x, y, z, blockid, state, playerid, {} )
end

function ClientSynchronizer:on_block_replaced_handler(blockid, x, y, z, playerid)
    local state = block.get_states(x, y, z)
    self:create_block_event(3, x, y, z, blockid, state, playerid, {} )
end

function ClientSynchronizer:on_block_broken_handler(blockid, x, y, z, playerid)
    self:create_block_event(2, x, y, z, blockid, 0, playerid, {} )
end

return ClientSynchronizer