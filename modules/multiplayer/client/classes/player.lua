require "multiplayer/global"

local Player = {}
Player.__index = Player

local MOVEMENT_SPEED = 8
local ROTATION_SPEED_FACTOR = 0.2

function Player.new(x, y, z, entity_id, username, disabled)
    if type(disabled) ~= "boolean" then disabled = true end
    local self = setmetatable({}, Player)

    self.entity_id = entity_id
    player.create("", entity_id)
    player.set_name(entity_id, username or "")
    if disabled then
        player.set_loading_chunks(entity_id, false)
        -- player.set_suspended(entity_id, true)
    end

    return self
end

function Player:set_loading_chunks(state)
    player.set_loading_chunks(self.entity_id, state)
end

function Player:move(x, y, z)
    player.set_suspended(self.entity_id, false)

    player.set_pos(self.entity_id, x, y, z)

    local entity = entities.get(player.get_entity( self.entity_id ))
    if entity then
        entity.rigidbody:set_enabled(false)
    end
end

function Player:rotate(yaw, pitch)
    player.set_suspended(self.entity_id, false)
    player.set_rot(self.entity_id, yaw, pitch, 0)
    local entity = entities.get(player.get_entity( self.entity_id ))
    if entity then
        entity.rigidbody:set_enabled(false)
    end
end

function Player:cheats(noclip, flight)
    player.set_noclip(self.entity_id, noclip)
    player.set_flight(self.entity_id, flight)
end

function Player:despawn()
    player.delete(self.entity_id)
    -- самоуничтожение
    self = nil
end

return Player
