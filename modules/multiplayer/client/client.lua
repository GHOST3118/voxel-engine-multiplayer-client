local Network = require "lib/network"
local session = require "multiplayer/global"
local protocol = require "lib/protocol"
local List = require "lib/common/list"
local state_machine = require "lib/common/fsm"
local Player = require "multiplayer/client/classes/player"
local login_handlers = require "multiplayer/client/dev/login_handlers"
local active_handlers= require "multiplayer/client/dev/active_handlers"
local WorldDataQueue = require "multiplayer/client/WorldDataQueue"

local ClientQueue = require "multiplayer/client/client_queue"
local NetworkPipe = require "multiplayer/client/network_pipe"

local Client = {}
Client.__index = Client

function Client.new(host, port)
    local self = setmetatable({}, Client)

    self.host = host
    self.port = port

    self.players = {}
    self.network = Network.new()

    self.handlers = {}
    self.on_disconnect = function () end
    self.on_connect = function () end
    self.state = nil

    self.fsm = state_machine.new()
    self.fsm:add_state(protocol.States.Login, {
        on_enter = login_handlers.on_enter( self ),
        on_event = login_handlers.on_event( self )
    })
    self.fsm:add_state(protocol.States.Active, {
        on_event = active_handlers.on_event( self )
    })

    -- приколы связанные с игроком
    self.x = 0
    self.y = 0
    self.z = 0
    self.yaw = 0
    self.pitch = 0
    self.player_id = 0
    self.entity_id = self.player_id
    -- двигался ли игрок последний тик
    self.moved = false

    self.chunks = {}
    self.moved_thru_chunk = false
    self.chunk_x = 0
    self.chunk_z = 0

    return self
end

function Client:push_packet(packet)
    local buffer = protocol.create_databuffer()
    buffer:put_packet(packet)
    List.pushright(ClientQueue, buffer.bytes)
end

function Client:connect()
    self.network:connect( self.host, self.port, function (status)
        if not status then error("Произошла какая-то ошибка, смотрите строки выше!") end

        self.fsm:transition_to( protocol.States.Login )
    end)
end

function Client:disconnect()
    self.network:disconnect()
    for _, value in ipairs(self.players) do
        value:despawn()
    end
    session.client = nil
end

function Client:world_tick()

    if not List.is_empty( WorldDataQueue ) then
        local data = List.popleft( WorldDataQueue )
        for key, value in ipairs(data) do
            block.set( value.x, value.y, value.z, value.block_id, value.block_state )
        end
    end
end

function Client:tick()

    NetworkPipe:process()
end

function Client:player_tick(playerid, tps)
    -- pass
    -- player_tick почему-то вызывается только если игрок ниже 256 уровня высоты.

    -- проверим двигался/поворачивался ли игрок
    local x, y, z = player.get_pos(playerid)
    local yaw, pitch = player.get_rot(playerid)
    if x ~= self.x or y ~= self.y or z ~= self.z or yaw ~= self.yaw or pitch ~= self.pitch then
        -- print(x, y, z, yaw, pitch)
        self.x = x self.y = y self.z = z self.yaw = yaw self.pitch = pitch
        self.moved = true
        local chunk_x, chunk_z = math.floor(session.client.x/16), math.floor(session.client.z/16)
        if chunk_x ~= self.chunk_x or chunk_z ~= self.chunk_z then
            self.moved_thru_chunk = true
            self.chunk_x = chunk_x self.chunk_z = chunk_z
        end
    end

end

function Client:on_block_placed(blockid, x, y, z, states)

    session.client:push_packet( protocol.build_packet("client", protocol.ClientMsg.BlockUpdate, x, y, z, states, blockid) )
end

function Client:on_block_broken(blockid, x, y, z)
    session.client:push_packet( protocol.build_packet("client", protocol.ClientMsg.BlockUpdate, x, y, z, 0, 0) )
end

return Client