local modname = ...
modname = modname:gsub("initCallbacks$", "") -- remove the suffix

local login = require(modname .. "login")
local Callbacks = require(modname .. "callbacks")
local Utils = require(modname .. "utils")

local initCallbacks = function(self)
	self.callbacks = {}
	for i, v in ipairs({
		"receive",		 -- server command received
		"join",			 -- a user joined a room
		"leave",		 -- a user left a room
		"messageBundle", -- a message bundle was received
        "chat",          -- a chat message was received
	}) do
		self.callbacks[v] = Callbacks:new()
	end 

	self.rawCallbacks = setmetatable({}, {__index = function(self, name) self[name] = Callbacks:new(); return self[name]; end}) -- Create a new callbacks table.
	-- TODO: find a better name for "raw" callbacks (which are callbacks for server messages, really)

	--[[
	self.websocket:on_message(function(websocket, message) -- When a server message is received.
		self.callbacks.messageBundle:fire(message) -- Fire the callback for a bundle of messages.
	end)
	--]]

    self.callbacks.messageBundle:register(function(message) -- When a message bundle is received.
		local roomID = message:match("^>(.-)\n") -- Get the room name.
		local messages
		if roomID then -- If the server sent a room name.
			messages = message:match("^>.-\n(.+)") -- Remove the room name from the messages.
		else
			messages = message -- Otherwise, just use the whole message.
			roomID = "lobby" -- And set the room name to lobby.
		end
		local room = self.rooms[roomID] -- Get the room.
		if not room then
			room = self:Room(roomID) -- Create the room if it doesn't exist.
			self.rooms[roomID] = room -- Add the room to the rooms table.
		end
		for message in messages:gmatch("([^\n]+)") do -- Loop through the messages.
			self.callbacks.receive:fire(message, room) -- Fire the receive callback for each message.
		end 
	end) 

	self.callbacks.receive:register(function(message, room) -- When a message is received.
		local command, args = message:match("|([^|]+)(.+)") -- Split the message into command and arguments.
		if command and command ~= "" then -- If the message has a command.
			self.rawCallbacks[command]:fire(room, Utils.split(args)) -- Fire the callback for the command.
		else -- Otherwise, the message is to be displayed as-is in the room. Possibly a log?
			-- TODO: find out.
		end
	end)

	self.rawCallbacks.updateuser:register(function(room, name, registered, avatar, settings) -- When the user is updated.
		self.users:changeName(self.self, name)
		self.self.name = name -- Set the nick.
		self.self.id = Utils.userID(name) -- Set the user ID.
		self.self.registered = registered -- Set the registered status.
		self.self.loggedIn = true
		self.self.avatar = avatar -- Set the avatar.
		self.self.psSettings = settings -- Set the settings.
		-- TODO: handle settings properly
	end)

	-- register a callback for the "c:" command, taking as arguments the room, timestamp, user, and message
	self.rawCallbacks["c:"]:register(function(room, timestamp, userID, ...)
		timestamp = tonumber(timestamp)
		-- join the vararg as a string with "|" as the separator
		local text = table.concat({...}, "|")
		local sender = self.users:getUser(userID) -- Get the user.
		local message = self:Message(text, sender, timestamp, room) -- Create a new message.
		room:message(message) -- Send the message to the room.
        self.callbacks.chat:fire(message)
	end)

	-- register a callback for the "c" command, taking as arguments the room, user, and message; instead, fire the "c:" callback, passing the current time as timestamp
	self.rawCallbacks["c"]:register(function(room, userID, ...)
		self.rawCallbacks["c:"]:fire(room, os.time(), userID, ...) -- Fire the "c:" callback.
	end)

	-- register a callback for the ":" command, taking as arguments the room and timestamp, storing the latter into the former as a number
	self.rawCallbacks[":"]:register(function(room, timestamp)
		room:setJoinTimestamp(tonumber(timestamp))
	end)

	-- register a callback for the "pm" command, taking as arguments the sender, the recipient, and the message
	self.rawCallbacks["pm"]:register(function(room, senderID, recipientID, ...)
		-- join the vararg as a string with "|" as the separator
		local text = table.concat({...}, "|")
		local sender = self.users:getUser(senderID) -- Get the sender.
		local recipient = self.users:getUser(recipientID) -- Get the recipient.

		local message = self:Message(text, sender, os.time(), nil, recipient) -- Create a new message.

		if message.self then -- If the sender is the user.
			recipient:message(sender, os.time(), message)
		else
			sender:message(sender, os.time(), message)
		end
		self.callbacks.chat:fire(message)
	end)

	-- register a callback for the "j" command, taking as arguments the room and user ID
	self.rawCallbacks["j"]:register(function(room, userID)
		local user = self.users:getUser(userID) -- Get the user.
		local room = self.rooms[roomID] -- Get the room.
		room:join(user) -- Join the room.
		user:join(room)
		self.callbacks.join:fire(user, room) -- Fire the join callback.
	end)

	-- register a callback for the "l" command, taking as arguments the room and user ID
	self.rawCallbacks["l"]:register(function(room, userID)
		local user = self.users:getUser(userID) -- Get the user.
		local room = self.rooms[roomID] -- Get the room.
		room:leave(user) -- Leave the room.
		user:leave(room)
		self.callbacks.leave:fire(user, room) -- Fire the leave callback.
	end)

	-- register a callback for the "n" command, taking as arguments the room, the user's new username and the old user ID
	self.rawCallbacks["n"]:register(function(room, newUsername, oldUserID)
		local user = self.users:getUser(oldUserID) -- Get the user.
		self.userlist:changeName(user, newUsername) -- Change the user's name.
	end)

	-- register a callback for the "init" command, setting the room type
    self.rawCallbacks["init"]:register(function(room, roomType)
        room:setType(roomType)
    end)

    --register a callback for the "title" command, setting the room name
    self.rawCallbacks["title"]:register(function(room, title)
        room:setName(title)
    end)

    --register a callback for the "users" command, setting the room userlist
    self.rawCallbacks["users"]:register(function(room, userlist)
        -- the first item of the userlist is the number of users; useless, but heh.
        local number, userlist = userlist:match("^(%d+),(.*)")
        -- loop through the userlist string, which is a comma-separated list of names
        for name in userlist:gmatch("[^,]+") do
            -- the first character is the rank, the rest is the name; optionally, the name ends by @ followed by ! if the user is away, then maybe the user status
            -- TODO: this _needs_ to be UTF-8 aware!
            local rank, name, away, status = name:match("^(.)(.+)@?(%!?)(.*)$")
            local user = self.users:getUser(name) -- get the user
            room:join(user, rank, true) -- join the room without firing a callback, as the user already is in the room
            user:join(room)
        end
    end)

	self.rawCallbacks.challstr:register(login(self)) -- When the challenge string is received, attempt login.
end

return initCallbacks