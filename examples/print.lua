local ps = require "ps"
local f = io.open("CREDENTIALS", "r")
local nick = f:read("*l")
local pass = f:read("*l")
local cqueues = require "cqueues"
f:close()

local client = ps.new()

--client.callbacks.receiveRaw:register(print)
client.callbacks.receive:register(function(...) print(...) end)

client:connect(nick, pass) -- Connect to the server.
client.loop:wrap(function()
    cqueues.sleep(5)
    client:send("|/join joim")
    cqueues.sleep(2)
    client:send("botdevelopment|/quit")
end)
print(client.loop:loop()) -- Start the event loop.

for err in client.loop:errors(1) do
    print(err)
end