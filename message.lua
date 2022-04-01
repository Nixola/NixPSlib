local utils = require "utils"

-- create a "message" class to store a message's text, sender, timestamp, room, and whether it's a private message
local methods = {}
local mt = {__index = methods}

local message = function(text, sender, timestamp, room, recipient)
	local t = setmetatable({}, mt)
	t.text = text
	t.sender = sender
	t.timestamp = timestamp
	t.room = room
	t.recipient = recipient
	return t
end

-- create a "reply" function that sends a message to the message sender if it's a private message, or to the message room otherwise
methods.reply = function(self, text)
	if self.private then
		self.sender:send(text)
	else
		self.room:send(text)
	end
end

return message