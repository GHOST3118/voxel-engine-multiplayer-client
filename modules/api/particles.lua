local PARTICLES_PID = {}
local module = {}

function module.emit(particle)
    local client_pid = gfx.particles.emit(
        particle.origin,
        particle.count,
        particle.preset,
        particle.extension
    )

    PARTICLES_PID[particle.pid] = client_pid
end

function module.stop(pid)
    gfx.particles.stop(PARTICLES_PID[pid])
    PARTICLES_PID[pid] = nil
end

function module.set_origin(particle)
    gfx.particles.set_origin(PARTICLES_PID[particle.pid], particle.origin)
end

return module