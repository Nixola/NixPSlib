local cqueues = require "cqueues"
local websocket = require "http.websocket"

local modname = ...
modname = modname:gsub("%.init$", "") -- remove the .init suffix
if modname ~= "" then modname = modname .. "." end

local Callbacks = require(modname .. "callbacks")
local Utils = require(modname .. "utils")
local initCallbacks = require(modname .. "initCallbacks")
local login = require(modname .. "login")

local ps = {} -- ps namespace
local methods = {} -- ps methods
methods.User = require(modname .. "user")
methods.Room = require(modname .. "room")
methods.Userlist = require(modname .. "userlist")
methods.Message = require(modname .. "message")
local mt = {__index = methods}


ps.new = function(url, cqueue)
	local t = setmetatable({}, mt) -- Create a new ps object.
	-- should url be that, or just sim.psim.us?
	t.url = url or "wss://sim3.psim.us/showdown/websocket" -- Set the URL.

	t.cqueue = cqueue -- Set the cqueue object for the event loop.

	t.queue = {} -- Create a queue for messages to be sent.
	-- TODO: ratelimit is 300ms for untrusted users, 100ms for trusted users; make it configurable
	t.queue.timeout = 0.3 -- Set the timeout for the queue.

	t.loop = cqueue or cqueues.new()

	t.websocket = websocket.new_from_uri(t.url) -- Create a websocket.

	t.rooms = {} -- Create a rooms table.

	t.users = t:Userlist() -- Create a userlist.

	initCallbacks(t) -- Initialize the callbacks.

	return t -- Return the ps object.
end

methods.connect = function(self, username, password, ...) -- Connect to the server.
	local cookies, timeout, out
	for i, v in pairs{...} do
		if type(v) == "number" then
			timeout = v
		elseif type(v) == "string" then
			cookies = v
		elseif type(v) == "table" then
			out = v
		end
	end
	timeout = timeout or 5 -- TODO: make the default timeout configurable
	login.setCredentials(username, password, cookies, out) -- Set the credentials.
	self.websocket:connect(timeout)

	self.loop:wrap(function() -- Create a timer for sending messages.
		while true do
			self:rawSend() -- Send the message and remove it from the queue.
			cqueues.sleep(self.queue.timeout) -- Timeout to prevent being throttled.
		end
	end)

	self.loop:wrap(function()
		while true do
			self:rawReceive() -- Receive a message bundle from the server.
		end
	end)
end

methods.send = function(self, str) -- Send a message to the server.
	self.queue[#self.queue+1] = str -- Add the message to the queue.
end

methods.rawSend = function(self) -- Send the first message in the queue and remove it.
	if self.queue[1] then
		self.websocket:send(self.queue[1])
		table.remove(self.queue, 1)
	end
end

methods.rawReceive = function(self, timeout) -- Receive a message from the server.
	local message
	if timeout then
		message = self.websocket:receive(timeout)
	else
		message = self.websocket:receive()
	end
	self.callbacks.messageBundle:fire(message)
end

methods.join = function(self, room) -- Join a room.
	self:send("|/join " .. room) -- Join the room.
end

return ps -- Return the ps namespace.