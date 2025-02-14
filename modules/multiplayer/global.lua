PACK_ID = "multiplayer"

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