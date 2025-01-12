local Network = require "lib/network"
local session = require "multiplayer/global"
local protocol = require "lib/protocol"
local List = require "lib/common/list"
local Player = require "multiplayer/client/classes/player"

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
    self.state = nil

    -- приколы связанные с игроком
    self.x = 0
    self.y = 0
    self.z = 0
    self.yaw = 0
    self.pitch = 0
    self.player_id = hud.get_player()
    -- двигался ли игрок последний тик
    self.moved = false

    self.chunks = {}
    self.moved_thru_chunk = false
    self.chunk_x = 0
    self.chunk_z = 0

    return self
end

function Client:connect()
    self.network:connect( self.host, self.port, function (status)
        if not status then error("Произошла какая-то ошибка, смотрите строки выше!") end
        local packet = protocol.create_databuffer()
        self.state = protocol.data.states.Login
        packet:put_packet(protocol.build_packet("client", protocol.ClientMsg.HandShake, pack.get_info("base").version, protocol.data.version, protocol.States.Login))
        self.network:send(packet.bytes)

        

        -- packet = protocol.create_databuffer()
        -- self.state = protocol.data.states.Login
        -- packet:put_packet(protocol.build_packet("client", protocol.ClientMsg.JoinGame, session.username))
        -- self.network:send(packet.bytes)
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

    

    -- проверим двигался/поворачивался ли игрок
    local x, y, z = player.get_pos()
    local yaw, pitch = player.get_rot()
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

    NetworkPipe:process()
end

function Client:player_tick(playerid, tps)
    -- pass
    -- player_tick почему-то вызывается только если игрок ниже 256 уровня высоты.
end

return Client