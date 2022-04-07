# NixPSlib
This is a Lua library to connect to [Pokémon Showdown](https://play.pokemonshowdown.com). I'm sure I'll come up with something else to say about it. Being just a connection library it doesn't really do anything on its own, though a couple of examples are included.
## Dependencies
Dependencies should be handled by LuaRocks. Though you can't install this library with LuaRocks yet. I'll work on it. Anyway, if you want to use this without LuaRocks and don't want to check the .rockspec file for the dependencies, it depends on the following rocks:

* `http`  
* `rapidjson`  

Of course, you should then check _their_ dependencies, too.

## Usage
The way you're supposed to use this is via [`cqueues`](http://25thandclement.com/~william/projects/cqueues.html), which is a dependency of [`http`](https://github.com/daurnimator/lua-http). You might be able to use it without it, but that's unsupported. Watch me still include a section on how you might be able to do it.
### Creating a connection
```lua
local ps = require "ps"
local client = ps.new(nick, pass[, url[, loop]])
```
The `nick` and `pass` are the credentials for the account you want to connect to. The `url` is the URL of the server you want to connect to. The `loop` is the cqueues event loop you want to use. If you don't specify it, it will create a new one, accessible as `client.loop`.

### Actually starting the connection
```lua
client:connect()
client.loop:loop()
```
This will start the connection and start the cqueues loop. `:loop()` will block until the connection is closed, so you need to handle anything else you might want to do using `cqueues`. Or you might want to avoid `cqueues` entirely, as mentioned above.

### Callbacks
In order to react to stuff happening on the server (which, if you're writing anything that uses this library, you're probably doing), you need to register callbacks for various events.  
Registering a callback is done by calling `callback:register`, which takes a function and, optionally, a string, as arguments. The function is called whenever the event occurs. The string is used as the ID of the function.  
In order to remove a callback, you can call `callback:remove` with the ID of the function you want to remove, if you provided one when registering it, or the function itself otherwise.
If you ever need to, you can fire all callbacks bound to an event by calling `callback:fire`, with the arguments that will be passed to all registered functions.

`client.callbacks` contains the following callbacks:
* `messageBundle`: called when the server sends one or more messages. The only argument is the raw string sent by the server. You probably don't want to use this ever, but you do you.
* `receive`: called for every message received in a "message bundle". Its arguments are the single, raw message, and a Room object representing the room it was sent in, or `lobby` if global. I might change that to `&` eventually, I dunno. As with `messageBundle`, you probably don't want to use this. But you do you.
* `join`: called whenever a user joins a room. The arguments are a User object representing the user, and a Room object representing the room they joined.
* `leave`: called whenever a user leaves a room. The arguments are a User object representing the user, and a Room object representing the room they left.
* `chat`: called whenever a user sends a message. The argument is a Message object containing sender, recipient (if any), room (if any; mutually exclusive with `recipient`), the text, and other stuff. This is the Callbacks section, not the Message section. Go check that out if you're interested.

`client.rawCallbacks` contains callbacks for any raw server commands, such as `c:`, `challstr`, `init` and whatnot. You shouldn't need to use these for basic functionality, but if you do, you can. You _will_ need to know PS' protocol to use any of these, as their arguments receive little to no parsing beforehand. Note that the arguments for these commands are obtained by splitting the raw message on `|`, so if any of your arguments can contain the pipe character, you'll need to join it back yourself. You can use varargs. You're smart, you'll figure it out.
Note: it doesn't contain a list of all the commands, but it'll accept pretty much anything as a key without ever throwing an error. If you register a callback for a non-existent command, it'll just silently ignore it.

### Objects
This library provides object representations for users, rooms, and messages. Probably something else, in the future.

#### User
The User object represents a user. It has the following properties:
* `name`: the user's name
* `id`: the user's ID
* `messages`: a table of private messages sent by or to the user
* `rooms`: a table of Room objects representing the rooms the user is in
Users also have the `send` method, that takes a single string as an argument, to send a private message to the user.

#### Room
The Room object represents a room. It has the following properties:
* `type`: either "chat" or "battle", depending on whether it's a chat room or a battle room
* `name`: the room's title, which is only set when the server actually tells us
* `id`: the room's ID
* `users`: a table of User objects representing the users in the room
* `ranks`: a table of strings representing the ranks of the users in the room, indexed by user object
* `messages`: a table of Message objects representing the messages that are sent in the room
* `joinTimestamp`: the timestamp the server sent when the room was joined
* `callbacks`: a table of callbacks, pretty self-explanatory: `join`, `leave`, `message`, fired whenever one of those events occurs
As with User objects, the `send` methods takes a string and sends it to the room.

#### Message
The Message object represents a message. It has the following properties:
* `sender`: the User object representing the user who sent the message
* `recipient`: the User object representing the user who received the message, if it was a private message
* `room`: the Room object representing the room the message was sent in, if it was sent in a room
* `text`: the text of the message
* `timestamp`: the time the message was sent
* `backlog`: a boolean representing whether the message is a backlog message, sent before the room was joined
* `self`: a boolean representing whether the message was sent by the user themselves
The `reply` method can be used to reply to the message, automatically sending a private message if the message is private or a room message otherwise.

### Use without cqueues
As promised, here's a section that might help you do something entirely unsupported. Still, open an issue if something's wrong. I might want to look into it. I'm not sure if I'll ever do that.  
The two things you need to handle yourself when not using a `cqueues` loop are sending and receiving messages. You'll need to periodically call `ps:rawReceive(timeout)`, which is blocking if you do not provide a timeout, to let the client poll for messages, and you'll need to periodically call `ps:rawSend()` to send messages. When sending, you don't want to exceed 3 messages per second if the user isn't trusted, or 10 if it is. The library usually handles ratelimiting on its own but, well, you're into unsupported territory.

## Todo
* Battles
* Better documentation (maybe)
* Better error handling
* A whole bunch of stuff, really; there's even an outdated TODO.md file with stuff I (mostly) already did.