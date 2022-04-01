local ev = require "ev" 
local websocket = require "websocket.client"

local Callbacks = require "callbacks"
local Utils = require "utils"
local initCallbacks = require "initCallbacks"

local ps = {} -- ps namespace
local methods = {} -- ps methods
methods.User = require "user"
methods.Room = require "room"
methods.Userlist = require "userlist"
local mt = {__index = methods}


ps.new = function(username, password, url, loop)
	local t = setmetatable({}, mt) -- Create a new ps object.
	-- should url be that, or just sim.psim.us?
	t.url = url or "ws://sim.psim.us:8000/showdown/websocket" -- Set the URL.
	t.credentials = {nick = username, password = password} -- Set the credentials.

	t.queue = {} -- Create a queue for messages to be sent.

	t.loop = loop or ev.Loop.new() -- Create a loop if none is provided.

	t.sendTimer = ev.Timer.new(function() -- Create a timer for sending messages.
		if t.queue[1] then -- If there is a message in the queue.
			t.websocket:send(t.queue[1]) -- Send the message.
			table.remove(t.queue, 1) -- Remove the message from the queue.
		end
	end, 0.01, 0.4) -- TODO: ratelimit is 300ms for untrusted users, 100ms for trusted users; make it configurable
	t.sendTimer:start(t.loop) -- Start the timer.

	t.websocket = websocket.ev({loop = t.loop}) -- Create a websocket.

	t.rooms = {} -- Create a rooms table.
	t.users = t:Userlist() -- Create a userlist.

	t.self = t:User(t.credentials.nick) -- Create a user for the bot.

	initCallbacks(t) -- Initialize the callbacks.

	return t -- Return the ps object.
end

methods.connect = function(self) -- Connect to the server.
	self.websocket:connect(self.url) 
end

methods.rawSend = function(self, str) -- Send a raw message.
	self.queue[#self.queue+1] = str -- Add the message to the queue.
end

return ps -- Return the ps namespace.