local fakeFile = function(str) -- create a fake file, storing the contents in a string, mocking the io library
	local file = {cursor = 0, content = str or ""}
	function file:read(arg)
		arg = arg or "l"
		local eof
		if self.cursor >= #self.content then
			eof = true
		end

		if type(arg) == "number" then -- read n bytes
			if eof then return nil end
			local str = self.content:sub(self.cursor, self.cursor + arg - 1)
			self.cursor = math.min(self.cursor + arg, #self.content)
			return str
		elseif (type(arg) ~= "string") then -- bad argument
			error("bad argument #1 to 'read' (number or string expected, got " .. type(arg) .. ")")
		elseif arg:match("^%*?l") then -- read a line from the current position
			if eof then return nil end
			local str = self.content:sub(self.cursor, self.content:find("\n", self.cursor) - 1)
			self.cursor = math.min(self.content:find("\n", self.cursor) + 1, #self.content)
			return str
		elseif arg:match("^%*?a") then -- read the entire file from the current position
			local str = self.content:sub(self.cursor)
			self.cursor = #self.content
			return str
		elseif arg:match("^%*?L") then -- read a line from the current position, including the newline
			if eof then return nil end
			local str = self.content:sub(self.cursor, self.content:find("\n\n", self.cursor))
			self.cursor = math.min(self.content:find("\n", self.cursor) + 1, #self.content)
			return str
		elseif arg:match("^%*?n") then -- read a number from the current position
			error("Reading a numeral is not implemented.")
		else -- bad argument
			error("bad argument #1 to 'read' (invalid format)")
		end
	end

	function file:write(...) -- write to the file, overwriting its contents from the current position
		local args = {...}
		for i, v in ipairs(args) do
			if type(v) ~= "string" then
				error("bad argument #" .. i .. " to 'write' (string expected, got " .. type(v) .. ")")
			end
		end
		local str = table.concat(args)
		self.content = self.content:sub(1, self.cursor - 1) .. ("\0"):rep(self.cursor - #str) ..  str .. self.content:sub(self.cursor + #str)
		self.cursor = self.cursor + #str
		return file
	end

	function file:seek(whence, offset) -- set the cursor position
		local cursor
		if whence == "set" then
			cursor = offset
		elseif whence == "cur" then
			cursor = self.cursor + offset
		elseif whence == "end" then
			cursor = #self.content + offset
		end
        if cursor < 0 then
            return nil, "Invalid argument", 22
        end
        self.cursor = cursor
		return self.cursor
	end

	function file:lines(...) -- return an iterator function that mimicks the behavior of standard file:lines
		local args = {...}
		if #args == 0 then
			args = {"*l"}
		end
		local iterator = function()
			if self.cursor >= #self.content then return nil end
			local t = {}
			-- store in t the results of read, iterating over the given args
			for i, v in ipairs(args) do
				t[i] = self:read(v)
			end
			return (unpack or table.unpack)(t)
		end
		return iterator
	end

	function file:setvbuf(mode, size) -- no need to implement this
		return
	end

    function file:flush() -- no need to implement this
        return
    end

	function file:close()
		return true
	end
	return file
end

return fakeFile