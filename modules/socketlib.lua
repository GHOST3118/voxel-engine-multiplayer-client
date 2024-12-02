

local SocketFramework = {}

-- Менеджер корутин
SocketFramework.coroutines = {}

function SocketFramework.runCoroutine(co)
    table.insert(SocketFramework.coroutines, co)
end

function SocketFramework.update()
    local active = {}
    for _, co in ipairs(SocketFramework.coroutines) do
        if coroutine.status(co) ~= "dead" then
            local success, err = coroutine.resume(co)
            if not success then
                print("Coroutine error:", err)
            else
                table.insert(active, co)
            end
        end
    end
    SocketFramework.coroutines = active
end

-- Обёртка над сокетами
SocketFramework.Socket = {}
SocketFramework.Socket.__index = SocketFramework.Socket

function SocketFramework.Socket.new(address, port)
    local self = setmetatable({}, SocketFramework.Socket)
    self.address = address
    self.port = port
    self.socket = nil
    self.connected = false
    return self
end

function SocketFramework.Socket:connect(callback)
    network.tcp_connect(self.address, self.port, function(sock)
        self.socket = sock
        self.connected = true
        if callback then
            callback(self)
        end
    end)
end

function SocketFramework.Socket:send(data)
    if not self.connected then
        error("Socket is not connected!")
    end

    local bytes = utf8.tobytes(data)

    self.socket:send(bytes)
end

function SocketFramework.Socket:receive(maxLength, callback)
    if not self.connected then
        error("Socket is not connected!")
    end
    SocketFramework.runCoroutine(coroutine.create(function()
        while self.connected do
            local data = self.socket:recv(maxLength)
            if data and #data > 0 then
                callback(utf8.tostring(data))
            end
            coroutine.yield()
        end
    end))
end

function SocketFramework.Socket:close()
    if self.socket then
        self.socket:close()
    end
    self.connected = false
end
return SocketFramework
-- Пример использования
-- local client = SocketFramework.Socket.new("127.0.0.1", 12345)
-- client:connect(function(sock)
--     print("Connected to server.")
--     sock:send("Hello, server!")
--     sock:receive(1024, function(data)
--         print("Received from server:", data)
--     end)
-- end)

-- Главный цикл
-- while true do
--     SocketFramework.update()
--     -- Добавьте паузу, чтобы избежать перегрузки процессора
--     os.execute("sleep 0.05")
-- end
