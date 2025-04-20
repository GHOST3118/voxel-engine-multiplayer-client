local events = start_require "api/events"
local rpc = require "api/rpc"
local bson = require "lib/common/bson"
local env = require "api/env"

local api = {
    events = events,
    rpc = rpc,
    bson = bson,
    env = env
}

return {client = api}