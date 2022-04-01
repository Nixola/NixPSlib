local utils = require "utils"

local methods = {}
local mt = {__index = methods}

local user = function(self, name) -- Create a new user.
    local t = setmetatable({}, mt) -- Create a new user object.
    t.name = name -- Set the user's name.
    t.id = utils.userID(name) -- Set the user's ID.
    t.messages = {} -- Create a table to store the chat with the user.
    t.rooms = {} -- Create a table to store the rooms.
    t.ps = self
    return t -- Return the user.
end

methods.changeName = function(self, name) -- Change the user's name.
    self.name = name -- Set the user's name.
    self.id = utils.userID(name) -- Set the user's ID.
    return self.id
end

-- Join a room adding it to the user's list of rooms, indexed by room ID.
methods.join = function(self, room, silent)
    local roomID = room.id
    self.rooms[roomID] = room
    if not silent then
        -- TODO: fire callback
    end
end

-- Leave a room removing it from the user's list of rooms, indexed by room ID.
methods.leave = function(self, room)
    local roomID = room.id
    self.rooms[roomID] = nil
end

return user