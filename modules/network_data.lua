local NetworkData = {}

function NetworkData.new(data)
    local self = setmetatable({}, NetworkData)
    self.playerid = data.playerid

    self.event = {}
    self.event.playerid = data.playerid
    self.event.player_name = data.player_name
    self.event.event_type = data.event_type

    self.event.position = {}
    self.event.position.x = data.position.x
    self.event.position.y = data.position.y
    self.event.position.z = data.position.z

    self.event.blockid = data.blockid
    self.event.state = data.state
    
    return self
end

return NetworkData