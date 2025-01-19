local session = require "multiplayer/global"

local Player = {}
Player.__index = Player

local MOVEMENT_SPEED = 8
local ROTATION_SPEED_FACTOR = 0.2

function Player.new(x, y, z, entity_id)
    local self = setmetatable({}, Player)

    self.head_angle = 0
    self.body_angle = 0

    self.entity = entities.spawn("base:player", {x, y, z})
    self.tsf = self.entity.transform
    self.rb = self.entity.rigidbody
    self.entity_id = entity_id

    self.rb:set_gravity_scale({ 0, 0, 0 })

    return self
end

function Player:move(x, y, z)
    local current_position = self.tsf:get_pos()
    local target_position = {x, y, z}

    if  session.client and 
        session.client.x == x and
        session.client.y == y and
        session.client.z == z
    then

        self.entity.skeleton:set_visible(false)
    end
    
    if current_position then
        self.rb:set_vel({
            (target_position[1] - current_position[1]) * MOVEMENT_SPEED,
            (target_position[2] - current_position[2]) * MOVEMENT_SPEED,
            (target_position[3] - current_position[3]) * MOVEMENT_SPEED
        })
    end
    
end

function Player:rotate(yaw, pitch)
    self:update_body_rotation(yaw)
    self:update_head_rotation(pitch)
end

function Player:update_head_rotation(target_rotation)
    self.head_angle = self.head_angle + (target_rotation - self.head_angle) * ROTATION_SPEED_FACTOR
    self.entity.skeleton:set_matrix(self.entity.skeleton:index("head"), mat4.rotate({1, 0, 0}, self.head_angle))
end

function Player:update_body_rotation(target_rotation)
    self.body_angle = self:smooth_rotation(self.body_angle, target_rotation, ROTATION_SPEED_FACTOR)
    self.entity.transform:set_rot(mat4.rotate({0, 1, 0}, self.body_angle))
end

function Player:smooth_rotation(start_angle, end_angle, factor)
    local angle_difference = end_angle - start_angle
    
    if math.abs(angle_difference) > 180 then
        end_angle = end_angle + (angle_difference > 0 and -360 or 360)
    end
    
    return start_angle + (end_angle - start_angle) * factor
end

function Player:despawn()
    self.entity:despawn()
    -- самоуничтожение
    self = nil
end

return Player