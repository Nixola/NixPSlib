--[[
This module allows for callback handling. It can probably be improved.
]]
local callbacks = {} -- callbacks namespace
callbacks.mt = {__index = callbacks} -- metatable

-- This function just creates a "callback object" giving it access to its "class"
-- methods.
callbacks.new = function(self)
	local c = setmetatable({}, self.mt) -- create a new callback object
	return c -- return the new callback object
end

-- Allows to register a callback for a specific event. Requires the actual callback
-- and a unique identifier.
callbacks.register = function(self, func, id)
	id = id or func -- If no id is given, use the function itself as id.

	if self[id] then return nil, "ID exists" end -- Check if the id already exists.
	if not (type(func) == "function") then return nil, "Invalid callback" end -- Check if the callback is a function.

	self[id] = func -- Add the callback to the table.
	return true -- Return true if everything went well.
end

-- Removes a callback with a specific ID, provided it actually exists.
callbacks.remove = function(self, id)

	if not self[id] then return nil, "ID does not exist" end -- Check if the id exists.

	self[id] = nil -- Remove the callback from the table.
	return true -- Return true if everything went well.
end

-- Fires all callbacks registered to the event. Any callbacks returning true will
-- be removed.
callbacks.fire = function(self, ...) -- TODO: handle errors
	for id, c in pairs(self) do -- Loop through all callbacks.
		if c(...) then -- If the callback returns true, remove it.
			self:remove(id) -- Remove the callback.
		end
	end
end 

setmetatable(callbacks, {__call = callbacks.new}) -- Set the metatable to call the constructor.
return callbacks -- Return the module.