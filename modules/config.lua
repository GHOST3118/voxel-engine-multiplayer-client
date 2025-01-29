local config = {}
local path = pack.shared_file("multiplayer", "config.toml")

function config.write()
    file.write(path, toml.tostring(config.data))
end

if file.exists( path ) then -- проверяем наличие конфига
    config.data = toml.parse( file.read(path) )
else
    config.data = toml.parse( file.read("multiplayer:default_config.toml") )
    config.write()
end

return config