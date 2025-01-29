require "multiplayer/global"

local Player = {}
Player.__index = Player

local MOVEMENT_SPEED = 8
local ROTATION_SPEED_FACTOR = 0.2

function Player.new(x, y, z, entity_id, username)
    local self = setmetatable({}, Player)

    self.entity_id = entity_id
    player.create("", entity_id)
    player.set_name(entity_id, username or "")

    return self
end

function Player:move(x, y, z)

    player.set_pos(self.entity_id, x, y, z)
    
    local entity = entities.get(player.get_entity( self.entity_id ))
    if entity then
        entity.rigidbody:set_enabled(false)
        entity.skeleton:set_interpolated(true)
    end
end

function Player:rotate(yaw, pitch)
    player.set_rot(self.entity_id, yaw, pitch)
    local entity = entities.get(player.get_entity( self.entity_id ))
    if entity then
        entity.rigidbody:set_enabled(false)
        entity.skeleton:set_interpolated(true)
    end
end

function Player:despawn()
    player.delete(self.entity_id)
    -- самоуничтожение
    self = nil
end

return Player
