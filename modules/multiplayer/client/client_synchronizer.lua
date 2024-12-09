local session = require "multiplayer/global"
local ClientSynchronizer = {}
ClientSynchronizer.__index = ClientSynchronizer

function ClientSynchronizer.new( network )
    local self = setmetatable({}, ClientSynchronizer)

    self.network = network

    return self
end

function ClientSynchronizer:handle_player(_event)
    local raw = _event

    if raw.EventPool then
        local event_pool = raw.EventPool
        for index, value in ipairs(event_pool) do
            local PlayerMoved = value
            if PlayerMoved then
                local movement_event = PlayerMoved.PlayerMoved
                if (movement_event.client_id ~= session.client_id) then
                    local _player
                    local entity
                    local pos = {}
                    table.insert(pos, movement_event.x)
                    table.insert(pos, movement_event.y)
                    table.insert(pos, movement_event.z)

                    if session.client.players[movement_event.client_id] then
                        _player = session.client.players[movement_event.client_id]
                        entity = _player.entity
                    else
                        
                        entity = entities.spawn("base:player", pos)
                        session.client.players[movement_event.client_id] = {
                            client_id = movement_event.client_id,
                            entity = entity
                        }
                    end

                    local tsf = entity.transform
                    local body = entity.rigidbody
                    tsf:set_pos(pos)
                    body:set_gravity_scale({0, 0, 0})
                end
            end
        end
    end
end

return ClientSynchronizer