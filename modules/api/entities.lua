local protocol = require "lib/protocol"

local module = {}
local entities_uids = {}
local entities_components = {}
local handlers = {}
local desyns_entities = {}

local spawn = entities.spawn

function entities.spawn(name, ...)
    local prefix = parse_path(debug.getinfo(2).source)
    if table.has(desyns_entities, name) or prefix == "multiplayer" then
        return spawn(name, ...)
    end

    local entity = spawn(name, ...)
    entity:despawn()

    local packet = protocol.build_packet("client", protocol.ClientMsg.EntitySpawnTry, entity:def_index(), {...})

    Session.client:push_packet(packet)

    return entity
end

function module.desync(name)
    table.insert(desyns_entities, name)
end

function module.sync(name)
    table.remove_value(desyns_entities, name)
end

function module.set_handler(triggers, handler)
    for _, trigger in ipairs(triggers) do
        handlers[trigger] = handler
    end
end

function module.__despawn__(uid)
    local cuid = entities_uids[uid]
    if not cuid then return end

    local entity = entities.get(cuid)
    if entity then
        entity:despawn()
        entities_uids[uid] = nil
    end
end

function module.__get_uids__()
    return entities_uids
end

function module.__emit__(uid, def, dirty)

    if not entities_uids[uid] then
        local centity = spawn(entities.def_name(def), {0, 0, 0})
        entities_uids[uid] = centity:get_uid()
        centity.rigidbody:set_gravity_scale({0, 0, 0})
    end

    local cuid = entities_uids[uid]
    local entity = entities.get(cuid)
    if not entity then return end

    if handlers[def] then
        handlers[def](cuid, def, dirty.custom_fields)
    end

    local standard_fields = dirty.standart_fields or {}
    local textures = dirty.textures or {}
    local components = dirty.components or {}
    local models = dirty.models or {}
    local tsf, body, rig = entity.transform, entity.rigidbody, entity.skeleton

    for key, val in pairs(textures) do
        rig:set_texture(key, val)
    end

    for key, val in pairs(models) do
        rig:set_model(tonumber(key), val)
    end

    for component, val in pairs(components) do
        local comp_tbl = entity:get_component(component)
        if not val then
            table.set_default(entities_components, cuid, {})
            if comp_tbl then
                for key, func in pairs(comp_tbl) do
                    if type(func) == "function" then
                        entities_components[cuid][key] = func
                        comp_tbl[key] = function() end
                    end
                end
            end
        else
            local comp_func = table.set_default(entities_components, cuid, {})
            for key, func in pairs(comp_func) do
                comp_tbl[key] = func
            end
        end
    end

    if standard_fields.tsf_pos then
        local cur_pos = tsf:get_pos()
        local target_pos = standard_fields.tsf_pos
        local direction = vec3.sub(target_pos, cur_pos)
        local distance = vec3.length(direction)

        if distance < 0.01 or distance > 10 then
            tsf:set_pos(target_pos)
            body:set_vel({0, 0, 0})
        else
            local time_to_reach = 0.1
            local speed = distance / time_to_reach
            local velocity = vec3.mul(vec3.normalize(direction), speed)
            body:set_vel(velocity)
        end
    end

    if standard_fields.tsf_rot then tsf:set_rot(standard_fields.tsf_rot) end
    if standard_fields.tsf_size then tsf:set_size(standard_fields.tsf_size) end
    if standard_fields.body_size then body:set_size(standard_fields.body_size) end
end

return module