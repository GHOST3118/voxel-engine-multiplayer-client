local module = {}

local IDS = {}

function module.show(wrap)
    local id = gfx.blockwraps.wrap(wrap.pos, wrap.texture)

    IDS[wrap.id] = id
end

function module.hide(id)
    if not IDS[id] then
        return
    end

    gfx.blockwraps.unwrap(IDS[id])

    IDS[id] = nil
end

function module.set_pos(wrap_id, pos)
    if not IDS[wrap_id] then
        return
    end

    local id = IDS[wrap_id]
    gfx.blockwraps.set_pos(id, pos)
end

function module.set_texture(wrap_id, texture)
    if not IDS[wrap_id] then
        return
    end

    local id = IDS[wrap_id]
    gfx.blockwraps.set_texture(id, texture)
end

return module