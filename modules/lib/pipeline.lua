local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline.new()
    local self = setmetatable({}, Pipeline)

    self._middlewares = {}

    return self
end

function Pipeline:add_middleware(func)
    if type(func) == "function" then

        table.insert( self._middlewares, func )
    end
end

function Pipeline:process( data )
    local result = data
    for index, callback in ipairs(self._middlewares) do
        result = callback( result )
    end

    return result
end