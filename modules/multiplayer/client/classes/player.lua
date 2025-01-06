local Player = {}
Player.__index = Player

function Player.new(x, y, z, uid, nickname)
    local self = setmetatable({}, Player)

    self.entity = entities.spawn("base:player", {x, y, z})

    self.entity_id = self.entity.eid
    self.uid = uid
    self.nickname = nickname
    player.set_entity(self.uid, self.entity_id)
    player.set_name(self.uid, self.nickname)

    return self
end

function Player:move(x, y, z)
    player.set_pos(self.uid, x, y, z)
end

function Player:rotate(yaw, pitch)
    player.set_rot(self.uid, yaw, pitch, 0)
end

function Player:despawn()
    entities.despawn(self.entity_id)
    -- самоуничтожение
    self = nil
end

-- function Player:add_middleware(func)
--     if type(func) == "function" then

--         table.insert( self._middlewares, func )
--     end
-- end

-- function Player:process( data )
--     local result = data or true
--     for index, callback in ipairs(self._middlewares) do
--         if result then
--             result = callback( result )
--         else
--             break
--         end

--     end

--     return result
-- end

return Player