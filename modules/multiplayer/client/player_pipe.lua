local Pipeline = require "lib/pipeline"
local session = require "multiplayer/global"
local Proto = require "multiplayer/proto/core"

local PlayerPipe = Pipeline.new()

local last_position = {0, 0, 0}
local last_rotation = {0, 0, 0}

PlayerPipe:add_middleware(function (playerid)
    if not session.client_id then
        return nil
    end

    local x, y, z = player.get_pos(playerid)
    local rx, ry, rz = player.get_rot(playerid)

    if last_position == {x, y, z} then
        return nil
    elseif last_rotation == {rx, ry, rz} then
        return nil
    end

    local message = {
        client_id = session.client_id,
        PlayerPosition = {
            x = x,
            y = y,
            z = z,
            yaw = ry,
            pitch = rx
        }
    }

    Proto.send_text(session.client.network, json.tostring( message ) )
    return playerid
end)


return PlayerPipe