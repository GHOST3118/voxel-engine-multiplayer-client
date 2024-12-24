local Network = require "lib/network"
local uuid = require "lib/uuid"
local List = require "lib/common/list"
local utils= require "lib/utils"

local ClientQueue = require "multiplayer/client/client_queue"
local NetworkPipe = require "multiplayer/client/network_pipe"
local ConnectionMessage = require "multiplayer/messages/connection"
local ChunkMessage = require "multiplayer/messages/chunk"
local session = require "multiplayer/global"
local ServerMessage = require "multiplayer/messages/server"

local Proto = require "multiplayer/proto/core"

local Client = {}
Client.__index = Client

function Client.new(host, port)
    local self = setmetatable({}, Client)

    self.host = host
    self.port = port

    self.loaded = {}

    self.players = {}
    self.network = Network.new()

    self.handlers = {}

    self.loadChunk = utils.createNthCallFunction(10, function (playerid)
        self:chunk_task(playerid)
    end)

    return self
end

function Client:queue_chunk(x, z)
    local request = ChunkMessage.ChunkRequest.new(x, z)

    self:queue_request( request, function (event)
        if event.Chunk then
            local chunk = base64.decode(event.Chunk)
            world.set_chunk_data( x, z, chunk, true )
            
        end
    end )
end

function Client:connect()
    self.network:connect( self.host, self.port, function (status)
        if status then
            local connect_message = ConnectionMessage.Connect.new(session.username, "0.25.3")

            self:queue_request( connect_message, function (event)
                if event.ConnectionAccepted then
                    console.log( "Успешное подключение к миру" )
                end
            end)
        end
    end )
    
end

function Client:queue_request( payload, cb )
    local request_uuid = uuid.getUUID()

    List.pushright( ClientQueue, {
        request_uuid = request_uuid,
        payload = payload
    } )
    self.handlers[ request_uuid ] = cb
end

function Client:disconnect()
    self.network:disconnect()
    session.client = nil

end

function Client:world_tick()
    NetworkPipe:process()
end

local function generate_chunk_table(player_x, player_z, radius)
    local chunks = {}

    -- Определяем центральный чанк
    local chunk_x = math.floor(player_x / 16)
    local chunk_z = math.floor(player_z / 16)

    -- Добавляем центральный чанк
    table.insert(chunks, {chunk_x, chunk_z})

    -- Перебор радиусов от центра
    for r = 1, radius do
        for dx = -r, r do
            for dz = -r, r do
                -- Обрабатываем только границу текущего радиуса
                if math.abs(dx) == r or math.abs(dz) == r then
                    table.insert(chunks, {chunk_x + dx, chunk_z + dz})
                end
            end
        end
    end

    return chunks
end

local chunk_queue = List.new()
function Client:chunk_task(playerid)
    local x, y, z = player.get_pos(playerid)
    
    local chunks = generate_chunk_table(x, z, 4)
    for index, chunk in ipairs(chunks) do
        if not(table.has(self.loaded, chunk[1]..":"..chunk[2])) then
            List.pushright( chunk_queue, chunk )
            table.insert(self.loaded, chunk[1]..":"..chunk[2])
        end
        
    end

    if not List.is_empty(chunk_queue) then
        local chunk = List.popleft( chunk_queue )

        self:queue_chunk( unpack(chunk) )
    end
end

function Client:player_tick(playerid, tps)
    
    self:loadChunk(playerid)
end

return Client