local ps = require "ps"
local f = io.open("CREDENTIALS", "r")
local nick = f:read("*l")
local pass = f:read("*l")
f:close()

local client = ps.new(nick, pass) -- TODO: get username and password from somewhere

local ev = require "ev" 

--client.callbacks.receiveRaw:register(print)
client.callbacks.receive:register(function(...) print(...) end)

client:connect() -- Connect to the server.
client.loop:loop() -- Start the event loop.