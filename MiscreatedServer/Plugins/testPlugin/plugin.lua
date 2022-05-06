-- example `./plugins/testPlugin/plugin.lua`
-- this creates a basic plugin that will be loaded by the game.
-- doesnt do much, but it shows how to define a plugin.
-- a plugin needs both a plugin.lua and a plugin.cfg file in a directory under `./plugins`.
-- the plugin dir should contain all files needed by the plugin.

local sayHello = function()
	LogWarning("Hello World!")
end

local sayGoodbye = function()
	LogError("Goodbye World!")
end

local saySomthing = function(something)
	local msg = "[testPlugin] -> " .. (something or "No Message");
	LogWarning(msg)
	return msg
end

local function loadPlugin()
	sayHello();
	return "testPlugin says Hello!"
end

local function unloadPlugin()
	sayGoodbye();
	return "testPlugin says Goodbye!"
end

--[[
	? name/description/author/version is required in plugin.lua to register the plugin.
	>> in plugin.cfg, name/description/author/version are mainly just for reference.
	>> but if specified name+version+author Must match the below values.
]]
return {
	name = "test plugin",
	version = '0.1a',
	description = "simple test plugin, prints 'Hello World!' onLoad and 'Goodbye World!' onUnLoad",
	author = "John Doe",
	onLoad = loadPlugin,
	onUnload = unloadPlugin,
	exports = {
		sayHello = sayHello,
		sayGoodbye = sayGoodbye,
		saySomthing = saySomthing
	}
}
