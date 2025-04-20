PACK_ID = "multiplayer"
CONTENT_PACKS = {}

ON_CONNECT = PACK_ID .. ":connect"
ON_DISCONNECT = PACK_ID .. ":disconnect"

if not Session then
    Session = {}

    Session.client = nil
    Session.server = nil
    Session.username = nil
    Session.ip = nil
    Session.port = nil

end

--- OTHER

function string.first_up(str)
    return (str:gsub("^%l", string.upper))
end

function time.formatted_time()
    local time_table = os.date("*t")

    local date = string.format("%04d/%02d/%02d", time_table.year, time_table.month, time_table.day)
    local time = string.format("%02d:%02d:%02d", time_table.hour, time_table.min, time_table.sec)

    local milliseconds = string.format("%03d", math.floor((os.clock() % 1) * 1000))

    local utc_offset = os.date("%z")
    if not utc_offset then
        utc_offset = "+0000"
    end

    return string.format("%s %s.%s%s", date, time, milliseconds, utc_offset)
end

function time.day_time_to_uint16(time)
    return math.floor(time * 65535 + 0.5)
end

logger = {}

function logger.log(text, type, only_save)
    type = type or 'I'
    type = type:upper()

    text = string.first_up(text)

    local source = file.name(debug.getinfo(2).source)
    local out = '[' .. string.left_pad(source, 20) .. '] ' .. text

    local uptime = time.formatted_time()

    local timestamp = string.format("[%s] %s", type, uptime)

    local path = "export:server.log"
    local message = timestamp .. string.left_pad(out, #out+33-#timestamp)

    if not only_save then
        print(message)
    end

    if not file.exists(path) then
        file.write(path, "")
    end

    local content = file.read(path)

    if #content > 100000 then
        content = ''
    end

    file.write(path, content .. message .. '\n')
end