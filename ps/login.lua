local modname = ...
modname = modname:gsub("login$", "") -- remove the suffix

local json = require "rapidjson"
local http = require "http.request"
local cookie = require "http.cookie"
local fakeFile = require(modname .. "utils.fakeFile")

local encode = function(str) 
  if str then
    str = string.gsub (str, "\n", "\r\n") -- replace newlines with CRLF
    str = string.gsub (str, "([^%w %-%_%.%~])", 
        function (c) return string.format ("%%%02X", string.byte(c)) end) -- encode all non-printable characters
    str = string.gsub (str, " ", "+") -- replace spaces with pluses
  end
  return str	
end

local get = function(url, t, cookies) -- perform a GET request
	local s = "?" -- start the query string
	for i, v in pairs(t) do -- loop through the parameters
		local item = encode(i) -- encode the parameter name
		if type(v) == "string" or type(v) == "number" then -- if the parameter is a string or number
			item = item .. "=" .. encode(tostring(v)) -- encode the parameter value
		end
		item = item .. "&" -- add a & to the query string
		s = s .. item -- add the parameter to the query string
	end
	s = s:match("^(.-)%&$") -- remove the trailing &
	local req = http.new_from_uri(url .. s) -- create the request

	local cookiesFile -- create a fake file for the cookies
	local cstore = cookie.new_store()
	if cookies then
		cookiesFile = fakeFile(cookies)
		cstore:load_from_file(cookiesFile)
	end
	req.cookie_store = cstore

	local headers, stream = req:go() -- send the request
	-- TODO: handle errors
	local body = stream:get_body_as_string() -- get the response body

	cookiesFile = fakeFile() -- reset the cookies fake file
	cstore:save_to_file(cookiesFile) -- get the string representation of the cookies
	cookiesFile:seek("set", 0)
	return body, cookiesFile:read("*a") -- return the request result
end

local post = function(url, body, cookies) -- perform a POST request
	local b = "" -- start the body
	for i, v in pairs(body) do -- loop through the parameters
		local p = (b == "") and "" or "&" -- add a & to the body if not the first parameter
		b = b .. p .. encode(i) .. "=" .. encode(v) -- add the parameter to the body
	end
	local req = http.new_from_uri(url) -- create the request

	local cookiesFile -- create a fake file for the cookies
	local cstore = cookie.new_store()
	if cookies then
		cookiesFile = fakeFile(cookies)
		cstore:load_from_file(cookiesFile)
	end
	req.cookie_store = cstore

	req.headers:upsert(":method", "POST") -- set the method to POST
	req.headers:upsert("content-type", "application/x-www-form-urlencoded") -- set the content-type
	req:set_body(b) -- set the body
	local headers, stream = req:go() -- send the request
	-- TODO: handle errors

	local body = stream:get_body_as_string() -- get the response body

	cookiesFile = fakeFile() -- reset the cookies fake file
	cstore:save_to_file(cookiesFile) -- get the string representation of the cookies
	cookiesFile:seek("set", 0)
	return body, cookiesFile:read("*a") -- return the request result
end

local login = {} 
local credentials = {} -- create a table to store the credentials
login.setCredentials = function(username, password, cookies, out) -- Provide a private way to set the credentials
	credentials.username = username
	credentials.password = password
	credentials.cookies = cookies
	credentials.out = out
end

local getAssertion = function(challstr) -- get the assertion from the server
	-- if the cookie is set, use it to perform an upkeep request
	if credentials.cookies then
		local data, cookies = get("https://play.pokemonshowdown.com/api/upkeep", {challstr = challstr}, credentials.cookies)
		if data:sub(1, 1) ~= "]" then -- if the upkeep failed
			print("Error. Aborting.")
			print(data)
			os.exit() -- TODO: handle gracefully, though I'm not even sure if this can happen anymore. EDIT: it can happen, on invalid requests.
		end
		data = json.decode(data:sub(2, -1)) -- decode the JSON data
		if data.loggedin and data.assertion then -- if the assertion was provided
			if credentials.out then
				credentials.out.cookies = cookies
				credentials.out.action = "upkeep"
			end
			return data.assertion, data.username -- return the assertion
		end
	end
	-- if the cookie is not set, perform a login request
	local t = {} -- create a table to store the parameters
	t.name = credentials.username -- set the nick
	t.pass     = credentials.password -- set the password
	t.challstr = challstr -- set the challenge string
	local data, cookies = post("https://play.pokemonshowdown.com/api/login", t) -- perform the POST login request

	if data:sub(1, 1) ~= "]" then -- if the login failed
		print("Error. Aborting.")
		print(data)
		os.exit() -- TODO: handle gracefully, though I'm not even sure if this can happen anymore. EDIT: it can happen, on invalid requests.
	end
	data = json.decode(data:sub(2, -1)) -- decode the JSON data
	
	if data.curuser.loggedin and data.assertion then -- if the assertion was provided
		if credentials.out then
			credentials.out.cookies = cookies
			credentials.out.action = "login"
		end
		return data.assertion, data.curuser.username -- return the assertion
	end

end

setmetatable(login, {__call = function(self, client) -- attempt to login
	return function(room, ...)
		local assertion, username = getAssertion(table.concat({...}, "|")) -- get the assertion
	    if assertion then -- if the login was successful
			client:send("|/trn " .. username .. ",0," .. assertion) -- send the login command
		else
			-- TODO: could not log in. Handle gracefully.
			print("Login failed.")
			os.exit(-1)
		end
 	end
end})

return login -- return the login function and the setCredentials function
