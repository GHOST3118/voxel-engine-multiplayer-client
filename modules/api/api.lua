local events = require "api/events"
local rpc = require "api/rpc"
local bson = require "lib/common/bson"

local api = {
    events = events,
    rpc = rpc,
    bson = bson
}

return {client = api}