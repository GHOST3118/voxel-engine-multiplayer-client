local config = require "config"

function on_open()
    document.username.text = config.data.profiles.current.username
end

function is_valid_username(str)
    str = str:trim()
    local len = utf8.length(str)
    return len >= 3 and len <= 20
end

function set_username()
    config.data.profiles.current.username = document.username.text
    config.write()
    menu.page = "servers"
end