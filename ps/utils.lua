local utils = {}

utils.split = function(str, sep) -- Split a string by a separator.
	sep = sep or "|" -- If no separator is given, use the default one.
	local t = {} -- Create a table to store the results.
	for c in str:gmatch("([^" .. sep .. "]+)") do -- Loop through the string.
		t[#t+1] = c -- Add the current result to the table.
	end
	return unpack(t)
end

utils.userID = function(str) -- Get the user ID from a user's name.
    return str:lower():gsub("%W+", "") -- Return the user ID.
end

return utils