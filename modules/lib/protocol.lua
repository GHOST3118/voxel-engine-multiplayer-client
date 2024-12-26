local protocol = {}
local data_buffer = require "core:data_buffer"
protocol.data = json.parse(file.read("multiplayer:modules/lib/protocol.json"))

-- нейронка вампала много помогла с кодированием в leb128

---Кодирование числа в формат LEB128
---@param n number Число для кодирования
---@return string encoded Закодированное число в строке
local function leb128_encode(n)
    local bytes = {}
    repeat
        local byte = n % 128
        n = math.floor(n / 128)
        if n ~= 0 then
            byte = byte + 128  -- Устанавливаем бит продолжения
        end
        table.insert(bytes, string.char(byte))
    until n == 0
    return table.concat(bytes)
end

---Декодирование числа из формата LEB128
---@param data string Строка для декодирования
---@param pos integer Позиция начала закодированной длины в данной таблице
---@return number result Декодированное число
---@return number bytesRead Количество прочитанных байт
local function leb128_decode(data, pos)
    if not pos then pos = 1 end
    local result = 0
    local shift = 0
    local bytesRead = 0
    for i = pos, #data do
        local byte = string.byte(data, i)
        local value = byte % 128
        result = result + value * (128 ^ shift)
        bytesRead = bytesRead + 1
        if byte < 128 then
            break
        end
        shift = shift + 1
    end
    return result, bytesRead+pos
end

---Кодирование строки
---@param str string Строка, которая будет закодирована
---@return table bytes Таблица с закодированной длиной строки
local function pack_string(str)
    local len = #str
    return utf8.tobytes(leb128_encode(len) .. str, true)
end

---Декодирование строки
---@param data table Таблица с закодированной длиной строки
---@param pos number Позиция счётчика в начале закодированной длины
---@return string string Декодированная строка
---@return number new_pos Новая позиция счётчика за концом строки
local function unpack_string(data, pos)
    data = utf8.tostring(data)
    local len, new_pos = leb128_decode(data, pos)
    return string.sub(data, new_pos, new_pos + len - 1), new_pos + len
end

-- Функции для кодирования и декодирования разных типов значений
local DATA_ENCODE = {
    ["boolean"] = function (buffer, value) buffer:put_bool(value) end,
    ["int8"] = function (buffer, value) buffer:put_byte(value < 0 and value + 256 or value) end,
    ["uint8"] = function (buffer, value) buffer:put_byte(value) end,
    ["int16"] = function (buffer, value) buffer:put_sint16(value) end,
    ["uint16"] = function (buffer, value) buffer:put_uint16(value) end,
    ["int32"] = function (buffer, value) buffer:put_sint32(value) end,
    ["uint32"] = function (buffer, value) buffer:put_uint32(value) end,
    ["int64"] = function (buffer, value) buffer:put_int64(value) end, -- есть проблемы с 64-битными числами
    ["uint64"] = function (buffer, value) buffer:put_int64(value) end,-- здесь тоже
    ["float"] = function (buffer, value) buffer:put_float32(value) end,
    ["double"] = function (buffer, value) buffer:put_float64(value) end,
    ["string"] = function (buffer, value) buffer:put_bytes(pack_string(value)) end,
    ["byteArray"] = function (buffer, value) buffer:put_bytes(utf8.tobytes(leb128_encode(#value), true)) buffer:put_bytes(value) end
}

local DATA_DECODE = {
    ["boolean"] = function (buffer) return buffer:get_bool() end,
    ["int8"] = function (buffer) return buffer:get_byte() end,
    ["uint8"] = function (buffer) return buffer:get_byte() end,
    ["int16"] = function (buffer) return buffer:get_sint16() end,
    ["uint16"] = function (buffer) return buffer:get_uint16() end,
    ["int32"] = function (buffer) return buffer:get_sint32() end,
    ["uint32"] = function (buffer) return buffer:get_uint32() end,
    ["int64"] = function (buffer) return buffer:get_int64() end, -- есть проблемы с 64-битными числами
    ["uint64"] = function (buffer) return buffer:get_int64() end,-- здесь тоже
    ["float"] = function (buffer) return buffer:get_float32() end,
    ["double"] = function (buffer) return buffer:get_float64() end,
    ["string"] = function (buffer)  local pos = buffer.pos
                                    local string, new_pos = unpack_string(buffer.bytes, pos)
                                    buffer:set_position(new_pos) return string end,
    ["byteArray"] = function (buffer)   local pos = buffer.pos
                                        local string, new_pos = unpack_string(buffer.bytes, pos)
                                        buffer:set_position(new_pos) return utf8.tobytes(string, true) end
}

---Создаёт датабуфер с порядком Big Endian
---@return table data_buffer Датабуфер
function protocol.create_databuffer()
    return data_buffer:new(nil, protocol.data.order)
end

---Создатель пакетов
---@param client_or_server string "client" или "server" - сторона, на которой генерируется пакет
---@param packet_type integer Тип пакета
---@param ... any Дополнительные параметры пакета
---@return table bytes Пакет
function protocol.build_packet(client_or_server, packet_type, ...)
    local args = {...}
    local buffer = protocol.create_databuffer()
    buffer:put_byte(packet_type-1)
    for key, value in pairs(protocol.data[client_or_server][packet_type]) do
        if key ~= 1 then DATA_ENCODE[string.explode(":", value)[2]](buffer, args[key-1]) end
    end
    return buffer.bytes
end

---Парсер пакетов
---@param client_or_server string "client" или "server" - сторона, откуда пришёл пакет
---@param data table Таблица с байтами (пакет)
---@return table parameters Список извлечённых параметров
function protocol.parse_packet(client_or_server, data)
    local result = {} -- вернём удобный список полученных значений
    local buffer = protocol.create_databuffer() -- для удобства создадим буфер
    buffer:put_bytes(data) -- запихаем в буфер все байты полученного пакета
    buffer:set_position(1) -- движок поставит позицию в конец буфера, возвращаем обратно в начало
    local packet_type = buffer:get_byte()+1
    for key, value in pairs(protocol.data[client_or_server][packet_type]) do
        if key ~= 1 then result[string.explode(":", value)[1]] = DATA_DECODE[string.explode(":", value)[2]](buffer) end
    end return result
end

-- TODO: чекер Protocol Packet
---Средство проверки пакета
---@param client_or_server string "client" или "server" - сторона, откуда пришёл пакет
---@param packet table Таблица с байтами (пакет)
---@return boolean success Успешность проверки пакета
function protocol.check_packet(client_or_server, packet)
    -- вопрос: на что чекать пакет?
    -- 1. было бы классно проверять, не наебал ли нас клиент/сервер с длиной пакета
    -- 2. теперь можно спарсить весь пакет, и если вдруг пакета не хватило или осталось с избытком, выкидываем нахрен из функции
    -- 3. если при парсинге пакета вдруг резко оказалось что тип пакета неизвестен, выкидываем
    -- проверки по типу соответствии никнейма со стандартом, длины никнейма и так далее будут за пределами этой функции
    -- только после успешной проверки функция вернёт true, а если нет - false или вообще nil, тогда сервер может кикнуть за malformed packet

    -- пока что будем считать, что все пакеты ровненькие и красивенькие
    return true
end

-- Перечисление сообщений клиента
protocol.ClientMsg = {}
-- Перечисление сообщений сервера
protocol.ServerMsg = {}

-- Парсим из json типы пакетов клиента и сервера
for index, value in ipairs(protocol.data.client) do
    protocol.ClientMsg[index] = value[1] --Имя типа пакета по индексу
    protocol.ClientMsg[value[1]] = index --Индекс по имени типа пакета
end
for index, value in ipairs(protocol.data.server) do
    protocol.ServerMsg[index] = value[1]
    protocol.ServerMsg[value[1]] = index
end

-- выставляем в свет функцию leb128_чего-то-там, но теперь функция возвращает таблицу с байтами и принимает тоже таблицу с байтами там, где были строки

---Кодирование числа в формат LEB128
---@param n number Число для кодирования
---@return table encoded Закодированное число в таблице байтов
protocol.leb128_encode = function (n) return utf8.tobytes(leb128_encode(n), true) end


---Декодирование числа из формата LEB128
---@param bytes table Таблица байт для декодирования
---@param pos integer Позиция начала закодированной длины в данной таблице
---@return number result Декодированное число
---@return number bytesRead Количество прочитанных байт
protocol.leb128_decode = function (bytes, pos) return leb128_decode(utf8.tostring(bytes), pos) end

-- !Это для тестов!
-- local test_packet = protocol.build_packet("server", protocol.ServerMsg.PlayerJoined, 53, "это очень длинный юзернейм, а учитывая, что кириллические символы кодируются двумя байтами, это вообще разрывная для проверки этого вашего leb128!", 2.34, 78.0, 7687.6145)
-- debug.print(protocol.parse_packet("server", test_packet))

-- test_packet = protocol.build_packet("server", protocol.ServerMsg.ChunkData, 63, 63, {124, 125, 126, 127, 128})
-- debug.print(protocol.parse_packet("server", test_packet))

-- debug.print(9871798, protocol.leb128_encode(9871798))
-- print(protocol.leb128_decode({182, 195, 218, 4}, 1))