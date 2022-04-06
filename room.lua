local utils = require "utils"
local Callbacks = require "callbacks"

local methods = {}
local mt = {__index = methods}

local room = function(self, id) -- Create a new room.
	local t = setmetatable({}, mt) -- Create a new room object.
	t.id = id -- Set the room ID.
	t.users = {} -- Create a table to store the users.
	t.ranks = {} -- Create a table to store the user ranks.
	t.messages = {} -- Create a table to store the messages.
	t.ps = self

	t.joinTimestamp = 0

	t.callbacks = {}
	-- create callbacks for "join", "leave", "message", "log"
	t.callbacks.join = Callbacks:new()
	t.callbacks.leave = Callbacks:new()
	t.callbacks.message = Callbacks:new()
	t.callbacks.log = Callbacks:new()
	return t -- Return the room.
end

methods.message = function(self, message) -- A message was sent in the room.
	self.messages[#self.messages + 1] = message -- Add the message to the messages table.
	self.callbacks.message:fire(message)
end

methods.setName = function(self, name) -- Set the room's name.
	self.name = name
end

methods.setType = function(self, type) -- Set the room's type.
	self.type = type
end

methods.setJoinTimestamp = function(self, timestamp) -- Set the room's join timestamp.
	self.joinTimestamp = timestamp
end

methods.setUserRank = function(self, user, rank) -- Set the rank of a user.
	self.ranks[user.id] = rank
end

methods.getUserRank = function(self, user) -- Get the rank of a user.
	return self.ranks[user.id]
end

methods.join = function(self, user, rank, silent) -- A user joined the room.
	local n = 1 -- The index of the user.
	for i, v in ipairs(self.users) do -- Loop through the users.
		n = i -- Set the index to the current user.
		if user.id < v.id then -- If the user's ID is less than the current user's ID.
			break -- Stop looping.
		end 
	end 
	table.insert(self.users, n, user) -- Insert the user into the users table in alphabetical order.
	self:setUserRank(user, rank) -- Set the user's rank.
	if not silent then
		-- TODO: fire callback
	end
end

methods.leave = function(self, user) -- A user left the room.
	for i, v in ipairs(self.users) do -- Loop through the users.
		if v.id == user.id then -- If the user's ID matches the user's ID.
			table.remove(self.users, i) -- Remove the user from the users table.
			break -- Stop looping.
		end
	end
	self.ranks[user.id] = nil -- Remove the user's rank.
end

methods.send = function(self, text) -- Send a message to the room.
	self.ps:send(self.id .. "|" .. text)
end

return room -- Return the room module.