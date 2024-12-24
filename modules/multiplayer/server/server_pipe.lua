local Pipeline = require "lib/pipeline"
local Proto = require "multiplayer/proto/core"
local Network = require "lib/network"
local AuthPipe = require "multiplayer/server/auth_pipe"
local MainPipe = require "multiplayer/server/main_pipe"
local List = require "lib/common/list"

local ServerPipe = Pipeline.new()



return ServerPipe
