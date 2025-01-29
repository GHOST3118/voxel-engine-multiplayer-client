local config = require "config"

function is_valid_address_port(str)
    local address
    local port_separator = str:find(':')
    if str == "" then return false end
    if not port_separator then
        return false
    end
    local port_string = str:sub(port_separator + 1)
    if not port_string:match("^%d+$") then
        return false
    end
    local port = tonumber(port_string)
    if port > 65535 then
        return false
    end
    return true
end

function is_valid_username(str)

end

local function parse_address(address_string)
    return address_string:match("([^:]+):(%d+)")
end

function connect()
    local username = document.username.text
    local host, port = parse_address(document.ip.text)

    events.emit(PACK_ID .. ":connect", username, host, port)
end

function add_server()
    config.data.multiplayer.servers[#config.data.multiplayer.servers+1] = {document.server_name.text, document.ip.text}
    config.write()
    menu.page="servers"
end