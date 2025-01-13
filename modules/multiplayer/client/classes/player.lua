local Player = {}
Player.__index = Player

function Player.new(x, y, z, entity_id)
    local self = setmetatable({}, Player)

    self.entity = entities.spawn("base:player", {x, y, z})
    self.tsf = self.entity.transform

    self.entity_id = entity_id

    return self
end

function Player:move(x, y, z)
    self.tsf:set_pos({x, y, z})
end

function Player:rotate(yaw, pitch)
    -- self.tsf:set_rot(yaw, pitch, 0)
end

function Player:despawn()
    self.entity:despawn()
    -- самоуничтожение
    self = nil
end

return Player