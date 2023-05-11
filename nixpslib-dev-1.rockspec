package = "NixPSlib"
version = "dev-1"
source = {
    url = "git://github.com/Nixola/NixPSlib"
}
description = {
    summary = "A Lua library to connect to Pokémon Showdown.",
    detailed = [[
        This is a library to facilitate a connection to Pokémon Showdown.
        Ideally, this lib could be used to write a bot or client for Pokémon Showdown
        without any knowledge of the protocol at all.
    ]],
    homepage = "http://github.com/Nixola/NixPSlib", -- We don't have one yet
    license = "zlib" -- or whatever you like
}
dependencies = {
    "http",
    "rapidjson",
    "cqueues",
}
build = {
    type = "builtin",
    modules = {
        ps = "ps/init.lua",
        ["ps.callbacks"] = "ps/callbacks.lua",
        ["ps.initCallbacks"] = "ps/initCallbacks.lua",
        ["ps.login"] = "ps/login.lua",
        ["ps.message"] = "ps/message.lua",
        ["ps.room"] = "ps/room.lua",
        ["ps.user"] = "ps/user.lua",
        ["ps.userlist"] = "ps/userlist.lua",
        ["ps.utils"] = "ps/utils/init.lua",
        ["ps.utils.fakeFile"] = "ps/utils/fakeFile.lua",
    }
}
