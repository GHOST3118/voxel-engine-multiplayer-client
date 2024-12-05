local ClientSynchronizer = {}
ClientSynchronizer.__index = ClientSynchronizer

function ClientSynchronizer.new( network )
    local self = setmetatable({}, ClientSynchronizer)

    self.network = network

    return self
end


return ClientSynchronizer