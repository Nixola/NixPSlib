local ps = require "ps"
local f = io.open("CREDENTIALS", "r") -- Read the credentials file.
local nick = f:read("*l") 
local pass = f:read("*l")
f:close()
io.stdout:setvbuf("no") -- Disable stdout buffering; useful for ANSI escape sequences.
local client = ps.new() -- Create a new client.

assert(pcall(require, "socket"), "LuaSocket is required for this specific example. For keyboard input, of all things. Go figure.")

client.callbacks.chat:register(function(msg) -- Register a callback for chat messages.
    local roomID = msg.room and msg.room.id or "PM" -- If the message is in a room, use the room's ID. Otherwise, use "PM".
    roomID = "#" .. roomID
    if #roomID > 7 then -- If the room ID is too long, shorten it.
        roomID = roomID:sub(1, 6) .. "…"
    end
    local time = os.date("%H:%M", msg.timestamp) -- Get the time of the message. 24h only, because I'm lazy.
    local sender = msg.sender.name -- Get the name of the sender.
    if #sender > 8 then -- If the name is too long, shorten it.
        sender = sender:sub(1, 7) .. "…"
    end
    io.write("\r\x1b[K") -- Clear the line.
    print(roomID, time .. " " .. sender .. ":", msg.text) -- Pretty-print the message.
end)

client.loop:wrap(function()
    local socket = require "socket"
    local cqueues = require "cqueues"
    local keyboard = socket.tcp() -- Create a raw TCP socket.
    keyboard:close() -- Turn it into a client socket.
    keyboard:setfd(0) -- Make it stdin.
    local recv = {keyboard} -- Create a table with the socket as the only element.
    while true do
        local read, _, err = socket.select(recv, nil, 0) -- Wait for input on stdin.
        if read[keyboard] then -- If there's input,
            client:send(io.read("*l")) -- Read a line from stdin and send it to the server.
            io.write("\x1b[A\x1b[K") -- Move the cursor up and clear the line that was just written.
        end
        cqueues.sleep(1) -- Sleep for a second, passing control to the event loop.
    end
end)

client.rawCallbacks.updateuser:register(function(_, nick)
    print("Your nickname is", nick) -- The server changed your nickname.
end)

client:connect(nick, pass) -- Connect to the server.
print(client.loop:loop()) -- Start the event loop.

for err in client.loop:errors(1) do
    print(err)
end