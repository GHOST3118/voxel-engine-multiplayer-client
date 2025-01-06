local List = require "lib/common/list"

local Player = {}
Player.__index = Player

function Player.new(active, network, username)
    local self = setmetatable({}, Player)

    self.active = false or active
    self.network = network
    self.username = username
    self.client_id = -1

    self.response_queue = List.new()
    self.received_packets = List.new()

    return self
end

function Player:is_active()
    return self.active
end

function Player:set_active(new_value)
    self.active = new_value
end

function Player:queue_response(event)
    List.pushright(self.response_queue, event)
end

return Player