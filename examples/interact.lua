local ps = require "ps"
local f = io.open("CREDENTIALS", "r")
local nick = f:read("*l")
local pass = f:read("*l")
f:close()
io.stdout:setvbuf("no")
local client = ps.new(nick, pass)

client.callbacks.chat:register(function(msg)
    local roomID = msg.room and msg.room.id or "PM"
    roomID = "#" .. roomID
    if #roomID > 7 then
        roomID = roomID:sub(1, 6) .. "…"
    end
    local time = os.date("%H:%M", msg.timestamp)
    local sender = msg.sender.name
    if #sender > 8 then
        sender = sender:sub(1, 7) .. "…"
    end
    io.write("\r\x1b[K")
    print(roomID, time .. " " .. sender .. ":", msg.text)
end)

client.loop:wrap(function()
    local socket = require "socket"
    local cqueues = require "cqueues"
    local keyboard = socket.tcp()
    keyboard:close()
    keyboard:setfd(0)
    local recv = {keyboard}
    while true do
        local read, _, err = socket.select(recv, nil, 0)
        if read[keyboard] then
            client:send(io.read("*l"))
            io.write("\x1b[A\x1b[K")
        end
        cqueues.sleep(1)
    end
end)

client.rawCallbacks.updateuser:register(function(_, nick)
    print("Your nickname is", nick)
end)

client:connect() -- Connect to the server.
print(client.loop:loop()) -- Start the event loop.

for err in client.loop:errors(1) do
    print(err)
end