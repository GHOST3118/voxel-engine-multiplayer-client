local events = start_require "api/events"
local entities = start_require "api/entities"
local env = start_require "api/env"
local rpc = require "api/rpc"
local bson = require "lib/common/bson"

local api = {
    events = events,
    rpc = rpc,
    bson = bson,
    env = env,
    entities = entities
}

return {client = api}