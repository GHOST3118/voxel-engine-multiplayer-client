local bincode = {}

-- нейронка вампала много помогла с кодированием в leb128

--- Кодирование числа в формат Bincode Varint
--- @param n number Число для кодирования
--- @return string encoded Закодированное число в строке
function bincode.bincode_varint_encode(n)
    local bytes = {}
    if n < 251 then
        table.insert(bytes, string.char(n))
    elseif n >= 251 and n < 2^16 then
        table.insert(bytes, string.char(251))
        table.insert(bytes, string.char(n % 256))
        table.insert(bytes, string.char(math.floor(n / 256)))
    elseif n >= 2^16 and n < 2^32 then
        table.insert(bytes, string.char(252))
        table.insert(bytes, string.char(n % 256))
        n = math.floor(n / 256)
        table.insert(bytes, string.char(n % 256))
        n = math.floor(n / 256)
        table.insert(bytes, string.char(n % 256))
        n = math.floor(n / 256)
        table.insert(bytes, string.char(n))
    elseif n >= 2^32 and n < 2^64 then
        table.insert(bytes, string.char(253))
        for i = 0, 7 do
          table.insert(bytes, string.char(n % 256))
          n = math.floor(n / 256)
        end
    -- Если добавить поддержку чисел больше 2^64, то придется либо использовать
    -- что-то кроме string.char (например, string.pack), либо работать с числами
    -- по частям, так как Lua 5.1 не поддерживает нативно целые числа больше 2^53.
    -- elseif n >= 2^64 and n < 2^128 then
    --     table.insert(bytes, string.char(254))
    --     -- ...
    else
        error("Bincode Varint encoding: Number too large for Lua 5.1")
    end
    return table.concat(bytes)
end

--- Декодирование числа из формата Bincode Varint
--- @param data string Строка для декодирования
--- @param pos integer Позиция начала закодированной длины в данной таблице
--- @return number result Декодированное число
--- @return number nextPos Позиция после декодированного числа
function bincode.bincode_varint_decode(data, pos)
    if not pos then pos = 1 end
    local firstByte = string.byte(data, pos)
    if firstByte < 251 then
        return firstByte, pos + 1
    elseif firstByte == 251 then
        local result = string.byte(data, pos + 1) + string.byte(data, pos + 2) * 256
        return result, pos + 3
    elseif firstByte == 252 then
        local result = string.byte(data, pos + 1) + string.byte(data, pos + 2) * 256
                     + string.byte(data, pos + 3) * 65536 + string.byte(data, pos + 4) * 16777216
        return result, pos + 5
    elseif firstByte == 253 then
      local result = 0
      for i = 1, 8 do
        result = result + string.byte(data, pos + i) * (256 ^ (i - 1))
      end
      return result, pos + 9
    -- elseif firstByte == 254 then
    --     -- ...
    else
        error("Bincode Varint decoding: Invalid marker byte")
    end
end

---Кодирование числа в формат LEB128
---@param n number Число для кодирования
---@return string encoded Закодированное число в строке
function bincode.leb128_encode(n)
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
function bincode.leb128_decode(data, pos)
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

return bincode