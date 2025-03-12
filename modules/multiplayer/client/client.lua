local Network = require "lib/network"
require "multiplayer/global"
local data_buffer = require "lib/common/data_buffer"
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
    -- присылал ли сервер местоположение клиента
    self.position_initialized = false

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

function Client:receive_packets(max_packets, ReceivedPackets)
    local packet_count = 0
    local MIN_BYTES_AVAILABLE = 2 -- TODO: Move to Config

    if not self.network.socket then
        return 0
    end

    while packet_count < max_packets and self.network.socket:available() > MIN_BYTES_AVAILABLE do

        local length_bytes = self.network:recieve_bytes(2)

        if length_bytes then
            local length_buffer = protocol.create_databuffer( length_bytes )
            local length = length_buffer:get_uint16()
            if length then
                local data_bytes_buffer = data_buffer()

                local data_bytes = self.network:recieve_bytes( length )
                while not data_bytes do
                    data_bytes = self.network:recieve_bytes( length )
                end
                data_bytes_buffer:put_bytes( data_bytes )
                while data_bytes_buffer:size() < length do
                    local data_bytes = self.network:recieve_bytes( length - data_bytes_buffer:size() )
                    if data_bytes then
                        
                        data_bytes_buffer:put_bytes( data_bytes )
                    end
                end

                data_bytes = data_bytes_buffer:get_bytes()

                if data_bytes then

                    local packet = protocol.parse_packet("server", data_bytes)

                    List.pushright(ReceivedPackets, packet)
                    packet_count = packet_count + 1
                else break end
            else break end
        else break end
    end

    return packet_count
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
    self = nil
end

function Client:world_tick()
    local blocks_per_tick = 500
    local blocks_placed = 0

    while blocks_placed < blocks_per_tick do
        if not List.is_empty( WorldDataQueue ) then
            local target_block = List.popleft( WorldDataQueue )

            if block.get( target_block.x, target_block.y, target_block.z ) ~= -1 then
                block.set( target_block.x, target_block.y, target_block.z, block.index(target_block.block_id), target_block.block_state )

                if block.get( target_block.x, target_block.y, target_block.z ) ~= block.index(target_block.block_id) then
                    List.pushright( WorldDataQueue, target_block )
                end
            else
                List.pushright( WorldDataQueue, target_block )
            end

            
        end

        blocks_placed = blocks_placed + 1
    end
    
end

function Client:tick()

    NetworkPipe:process()
end

function Client:await_join()
    local join = List.new()

    self:receive_packets(1, join)
    if not List.is_empty( join ) then
        local packet = List.popleft( join )
        self.fsm:handle_event( packet )
    end
end

function Client:player_tick(playerid, tps)
    -- pass
    -- player_tick почему-то вызывается только если игрок ниже 256 уровня высоты.

    -- проверим двигался/поворачивался ли игрок
    local x, y, z = player.get_pos(playerid)
    local yaw, pitch = player.get_rot(playerid)
    if x ~= self.x or y ~= self.y or z ~= self.z or yaw ~= self.yaw or pitch ~= self.pitch then
        -- print(x, y, z, yaw, pitch)
        self.x = x
        self.y = y
        self.z = z
        self.yaw = yaw
        self.pitch = pitch
        self.moved = true
        local chunk_x, chunk_z = math.floor(self.x/16), math.floor(self.z/16)
        if chunk_x ~= self.chunk_x or chunk_z ~= self.chunk_z then
            self.moved_thru_chunk = true
            self.chunk_x = chunk_x self.chunk_z = chunk_z
        end
    end

end


function Client:on_block_set(blockid, x, y, z, states, rotation)
    rotation = rotation or block.get_rotation(x, y, z)
    self:push_packet( protocol.build_packet("client", protocol.ClientMsg.BlockUpdate, x, y, z, states, rotation, blockid) )
end

function Client:on_block_placed(blockid, x, y, z, states, rotation)
    rotation = rotation or block.get_rotation(x, y, z)
    self:push_packet( protocol.build_packet("client", protocol.ClientMsg.BlockUpdate, x, y, z, states, rotation, blockid) )
end

function Client:on_block_broken(blockid, x, y, z)
    self:push_packet( protocol.build_packet("client", protocol.ClientMsg.BlockUpdate, x, y, z, 0, 0, 0) )
end

function Client:on_block_interact(blockid, x, y, z, states)
    self:push_packet( protocol.build_packet("client", protocol.ClientMsg.BlockInteract, x, y, z) )
end

local buffer = {}
function Client:on_chunk_present(x, z, is_loaded)
    if #buffer < core.get_setting("chunks.load-distance") then
        table.insert(buffer, x)
        table.insert(buffer, z)
        return
    end

    local packet = protocol.build_packet("client", protocol.ClientMsg.RequestChunks, buffer)
    self:push_packet( packet )
    buffer = {x, z}
end

return Client