local modname = ...
modname = modname:gsub("userlist$", "") -- remove the suffix

local Utils = require(modname .. "utils")

-- create a userlist class to store a list of users, indexed by user ID, and able to retrieve them by name
local methods = {}
local mt = {__index = methods}

local userlist = function(self)
	local t = setmetatable({}, mt)
	t.users = {}
    t.ps = self -- set the parent ps object
	return t
end

methods.getUser = function(self, username)
    local userID = Utils.userID(username)
	local user = self.users[userID]
    -- if the user doesn't exist, create a new user
    if user == nil then
        user = self.ps:User(username)
        self.users[userID] = user
    end
    return user
end

methods.changeName = function(self, user, newName)
    local oldUserID = user.id
    local newUserID = user:changeName(newName)
    self.users[oldUserID] = nil
    self.users[newUserID] = user
end

return userlist