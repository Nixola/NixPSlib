local ps = require "ps"
local Utils = require "ps.utils"
local f = io.open("NixPSlib/CREDENTIALS", "r")
local nick = f:read("*l")
local pass = f:read("*l")
local mastersLine = f:read("*l")
local masters = {}
local prefix = "§"

-- apply Utils.userID to each mastersLine comma-separated element and store them in masters as keys
for master in mastersLine:gmatch("[^,]+") do
    masters[Utils.userID(master)] = true
end

f:close()

local client = ps.new(nick, pass)
client.callbacks.chat:register(function(message)
    print(string.format("% -15s", message.sender.name), message.text)
    if not (message.backlog or message.self) then
        if message.text:match("^" .. prefix) and masters[message.sender.id] then
            client:join(message.text:match("^" .. prefix .. "(.+)$"))
        else
            message:reply(message.text)
        end
    end
end)

client:connect() -- Connect to the server.
print(client.loop:loop()) -- Start the event loop.

for err in client.loop:errors(1) do
    print(err)
end