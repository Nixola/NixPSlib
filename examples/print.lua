local ps = require "init"
local f = io.open("CREDENTIALS", "r")
local nick = f:read("*l")
local pass = f:read("*l")
f:close()

local client = ps.new(nick, pass)

--client.callbacks.receiveRaw:register(print)
client.callbacks.receive:register(function(...) print(...) end)

client:connect() -- Connect to the server.
print(client.loop:loop()) -- Start the event loop.

for err in client.loop:errors(1) do
    print(err)
end