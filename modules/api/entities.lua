local module = {}
local __entities = {}
local handlers = {}

local spawn = entities.spawn
local reg_entities = {}

local utils = require "lib/utils"

function entities.spawn(name, ...)
    if table.has(reg_entities, name) then
        return spawn(name, ...)
    end
end

function module.register(name)
    table.insert(reg_entities, name)
end

function module.unregister(name)
    table.remove_value(reg_entities, name)
end

function module.set_handler(triggers, handler)
    for _, trigger in ipairs(triggers) do
        handlers[trigger] = handler
    end
end

function module.__despawn__(uid)
    local cuid = __entities[uid]

    if not cuid then
        return
    end

    local entity = entities.get(cuid)
    if entity then
        entity:despawn()
        __entities[uid] = nil
    end
end

function module.__emit__(uid, def, dirty)
    if not __entities[uid] then
        local centity = spawn(entities.def_name(def), {0, 0, 0})
        __entities[uid] = centity:get_uid()
        centity.rigidbody:set_gravity_scale({0, 0, 0})
    end

    local cuid = __entities[uid]

    if handlers[def] then
        handlers[def](cuid, def, dirty.custom_fields)
    end

    local standard_fields = dirty.standart_fields or {}
    local textures = dirty.textures or {}

    local entity = entities.get(cuid)

    if not entity then
        return
    end

    local tsf, body, rig = entity.transform, entity.rigidbody, entity.skeleton

    for key, val in pairs(textures) do
        rig:set_texture(key, val)
    end

    if standard_fields.tsf_pos then
        local cur_pos = tsf:get_pos()
        local target_pos = standard_fields.tsf_pos

        local direction = vec3.sub(target_pos, cur_pos)
        local distance = vec3.length(direction)

        if distance < 0.01 or distance > 10 then
            tsf:set_pos(target_pos)
            body:set_vel({0, 0, 0})
            goto f_end
        end

        local time_to_reach = 0.1
        local speed = distance / time_to_reach
        local velocity = vec3.mul(vec3.normalize(direction), speed)

        body:set_vel(velocity)
        ::f_end::
    end
    if standard_fields.tsf_rot then
        tsf:set_rot(standard_fields.tsf_rot)
    end
    if standard_fields.tsf_size then
        tsf:set_size(standard_fields.tsf_size)
    end

    if standard_fields.body_size then
        body:set_size(standard_fields.body_size)
    end
end

return module