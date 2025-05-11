local module = {}
local __entities = {}
local handlers = {}

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
        local centity = entities.spawn(entities.def_name(def), {0, 0, 0})
        __entities[uid] = centity:get_uid()
    end

    local cuid = __entities[uid]

    if handlers[def] then
        handlers[def](cuid, def, dirty.custom_fields)
    end
    local standard_fields = dirty.standart_fields

    local entity = entities.get(cuid)
    local tsf, body = entity.transform, entity.rigidbody

    if standard_fields.tsf_pos then
        tsf:set_pos(standard_fields.tsf_pos)
    end
    if standard_fields.tsf_rot then
        tsf:set_rot(standard_fields.tsf_rot)
    end
    if standard_fields.tsf_size then
        tsf:set_size(standard_fields.tsf_size)
    end

    if standard_fields.body_phys ~= nil then
        body:set_enabled(standard_fields.body_phys)
    end

    if standard_fields.body_size then
        body:set_size(standard_fields.body_size)
    end
end

return module