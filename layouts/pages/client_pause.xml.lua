function disconnect()
    if Session.client then
        Session.client:disconnect()
    end
    core.close_world(true)
end
