package = "NixPSlib"
version = "dev-1"
source = {
    url = "https://github.com/Nixola/NixPSlib"
}
description = {
    summary = "A Lua library to connect to Pokémon Showdown.",
    detailed = [[
        This is a library to facilitate a connection to Pokémon Showdown.
        Ideally, this lib could be used to write a bot or client for Pokémon Showdown
        without any knowledge of the protocol at all.
    ]],
    homepage = "http://...", -- We don't have one yet
    license = "none yet" -- or whatever you like
}
dependencies = {
    "http",
    "rapidjson",
}
build = {
    type = "builtin",
    modules = {
        ps = "init.lua",
    }
}
