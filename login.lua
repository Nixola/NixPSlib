local json = require "rapidjson"
local https = require "ssl.https"

local encode = function(str) 
  if str then
    str = string.gsub (str, "\n", "\r\n") -- replace newlines with CRLF
    str = string.gsub (str, "([^%w %-%_%.%~])", 
        function (c) return string.format ("%%%02X", string.byte(c)) end) -- encode all non-printable characters
    str = string.gsub (str, " ", "+") -- replace spaces with pluses
  end
  return str	
end

local get = function(url, t) -- perform a GET request
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
	return https.request(url .. s), url..s -- return the request result and the url
end

local post = function(url, body) -- perform a POST request
	local b = "" -- start the body
	for i, v in pairs(body) do -- loop through the parameters
		local p = (b == "") and "" or "&" -- add a & to the body if not the first parameter
		b = b .. p .. encode(i) .. "=" .. encode(v) -- add the parameter to the body
	end
	return https.request(url, b) -- return the request result
end

local login = function(client) -- attempt to login
	return function(room, ...)
		local t = {} -- create a table to store the parameters
		t.act  = "login" -- set the action to login
	    t.name = client.credentials.nick -- set the nick
		t.pass     = client.credentials.password -- set the password
		t.challstr = table.concat({...}, "|") -- set the challenge string
	    local data, body = post("https://play.pokemonshowdown.com/action.php", t) -- perform the POST login request
	    if data:sub(1, 1) ~= "]" then -- if the login failed
	    	print("Error. Aborting.")
	    	print(data)
	    	os.exit() -- TODO: handle gracefully, though I'm not even sure if this can happen anymore
	    end
	    data = json.decode(data:sub(2, -1)) -- decode the JSON data
	    if data.actionsuccess then -- if the login was successful
	 	    assertion = data.assertion -- get the assertion
			client:rawSend("|/trn " .. (t.name or t.userid) .. ",0," .. assertion) -- send the login command
		else
			-- TODO: could not log in. Handle gracefully.
			print("Login failed.")
			os.exit(-1)
		end
 	end
end

return login -- return the login function