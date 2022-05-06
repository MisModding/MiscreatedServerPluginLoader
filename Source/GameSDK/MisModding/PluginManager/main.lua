local FS = require 'FileSystem'; ---@type Module.FileSystem
local configReader = require 'configReader'; ---@type configReader
local Class = require 'ClassBuilder'; ---@type ClassBuilder
local Events = require 'MisModding.Common.eventManager'; ---@type eventManager

Script.LoadScriptFolder 'MisModding/PluginManager/Classes'
local Plugin = require 'MisModding.PluginManager.Classes.Plugin'; ---@type MisModding.mPlugin

--- default Plugin options.
local pluginOpts = {
    --- The name of the plugin.
    name = '',
    --- The version of the plugin.
    version = '',
    --- The author of the plugin.
    author = '',
    --- The description of the plugin.
    description = '',
    --- AutoLoad Config.
    AutoLoad = {Enabled = false},
    --- dependencies [{name = "", version = ""}]
    ---@type table<string,string>
    DependsOn = nil,
}

local plugin_manager = Class {plugins = {}};

function plugin_manager:new()
    self.Config = {};
    self.events = Events(); ---@type eventManager
    self.plugins = {};

    self.events:observe(
        'plugin.load', function(event, data)
            local eventType = event.type;
            local plugin = data.plugin;
            self.Logger(string.expand('[${kind}] -> ${name} loaded', {kind = eventType, name = plugin.name, version = plugin.version}))
        end, true
    )

    self.events:observe(
        'plugin.unload', function(event, data)
            local eventType = event.type;
            local plugin = data.plugin;
            self.Logger(string.expand('[${kind}] -> ${name}@(${version}) unloaded', {kind = eventType,name = plugin.name, version = plugin.version}))
        end, true
    )

    self.events:observe(
        'plugin.error', function(event, data)
            local eventType = event.type;
            local plugin = data.plugin;
            self.Logger(
                string.expand(
                    '[${kind}] -> ${name}@(${version}) >> ${error}',
                    {kind = eventType, name = plugin.name, version = plugin.version, error = data.error}
                )
            )
        end, true
    )

    self.events:observe(
        'plugin.debug', function(event, data)
            local eventType = event.type;
            local plugin = data.plugin;
            self.Logger(
                string.expand(
                    '${kind}] -> ${name}@${version} >> ${message}',
                    {kind = eventType, name = plugin.name, version = plugin.version, message = data.message}
                )
            )
        end, true
    )
end

plugin_manager.Logger = function(msg) Log('{{PluginManager}} %s', msg) end

--- check a plugins dependencies
---@param dependencies table
function plugin_manager:checkPluginDependancies(dependencies)
    if dependencies then
        for name, version in pairs(dependencies) do
            local found = false
            for _, loaded_plugin in pairs(self.plugins) do
                if loaded_plugin.name == name and loaded_plugin.version == version then
                    found = true
                    break
                end
            end
            if not found then
                return false, string.expand(
                           'missing dependency ${name}@(${version})', {name = name, version = version}
                       )
            end
        end
    end
    return true
end

function plugin_manager:loadPlugin(name, path, ...)
    local config = {};

    local pluginDir = FS.dir_name(path);
    local pluginCfgFile = FS.joinpath(pluginDir, 'plugin.cfg');
    --- check if the config file exists
    if FS.isFile(pluginCfgFile) then
        config = configReader.read(pluginCfgFile, {smart = true, list_delim = ';', trim_quotes = true})
    end

    local result = Plugin(pluginDir, config);
    if (not result) then return false, result end
    if (not result) then
        self.events:emit(
            'plugin.error', {plugin = {name = name, version = 'undefined'}, error = 'could not load plugin from ' .. path}
        )
        return false, 'plugin failed to load: returned nil'
    end
    local plugin = result.plugin;
    if (plugin.name ~= name) then
        self.events:emit(
            'plugin.error',
            {plugin = {name = name, version = (plugin.version or 'undefined')}, error = 'plugin mismatch in ' .. path}
        )
        return false, 'provided plugin name does not match the loaded plugin'
    end
    table.insert(self.plugins, result)

    --- check for plugin dependencies
    if type(result.DependsOn) == 'table' then
        local HasAllDependencies, dependencyError = self:checkPluginDependancies(result.DependsOn)
        if not HasAllDependencies then
            self.events:emit(
                'plugin.error', {plugin = {name = name, version = (plugin.version or 'undefined')}, error = dependencyError}
            )
            return false, dependencyError
        end
    end
    local pluginConfig = result.config
    if not (pluginConfig['Settings'].enabled == "true") then
        self.events:emit(
            'plugin.load', {
                plugin = {name = name, version = (plugin.version or 'undefined')},
                message = 'plugin skipped as disabled',
            }
        )
        return false
    end
    --- handle plugin Load
    if type(plugin['onLoad']) == 'function' then
        --- validate plugin loaded using pcall
        local success, message = pcall(plugin.onLoad, ...);
        if not success then
            self.events:emit(
                'plugin.error',
                {plugin = {name = name, version = (plugin.version or 'undefined')}, error = message or 'unknown error'}
            )
            return false, 'plugin failed to load: ' .. message
        end
        self.events:emit(
            'plugin.load', {
                plugin = {name = name, version = (plugin.version or 'undefined')},
                message = (message or 'plugin loaded successfully'),
            }
        )
        return true, (message or 'plugin loaded successfully')
    end
end

local function validPluginConfig(pluginConf)
    if (type(pluginConf) ~= 'table') then return false, 'plugin config must be a table' end
    if (type(pluginConf['name']) ~= 'string') then return false, 'plugin config must have a name' end
    if (type(pluginConf['version']) ~= 'string') then return false, 'plugin config must have a version' end
    if (pluginConf['description'] ~= nil) then
        if (type(pluginConf['description']) ~= 'string') then return false, 'plugin config must have a description' end
    end
    if (pluginConf['author'] ~= nil) then
        if (type(pluginConf['author']) ~= 'string') then return false, 'plugin config must have an author' end
    end
    if (type(pluginConf['AutoLoad']) == 'table') then
        if type(pluginConf['AutoLoad'].enabled) ~= 'string' then
            return false, 'plugin config AutoLoad.Enabled bust be a string'
        end
    end
    if (pluginConf['DependsOn'] ~= nil) then
        if (type(pluginConf.DependsOn) ~= 'table') then return false, 'plugin config must have a dependsOn config' end
    end
    return true
end

--- plugin_manager:autoLoadPlugins(AutoLoadConf)
--- loads all plugins in the given path, if they are not already loaded and pass dependency checks
--- there must be both a plugin.cfg and a plugin.lua file in the path
---@param AutoLoadConf table AutoLoad configuration
function plugin_manager:autoLoadPlugins(AutoLoadConf)
    local pluginsToLoad = {};

    -- first find our plugins.

    local path = AutoLoadConf.PluginDir;
    if not FS.isDir(path) then return end
    ---@diagnostic disable-next-line: undefined-field
    local folders = System.ScanDirectory(path, SCANDIR_SUBDIRS)
    for _, pluginDir in pairs(folders) do
        if FS.isFile(FS.joinpath(path, pluginDir, 'plugin.cfg')) then
            -- load plugin config
            local pluginConfig = configReader.read(FS.joinpath(path, pluginDir, 'plugin.cfg'),{
                                                                    smart = true,
                                                                    list_delim = ';',
                                                                    trim_quotes = true
                                                                })
            if not pluginConfig then
                self.events:emit(
                    'plugin.error', {
                        plugin = {name = pluginDir, version = 'undefined'},
                        error = 'failed loading plugin, could not read plugin.cfg',
                    }
                )
                break
            end

            if pluginConfig.enabled == 'false' then
                self.events:emit(
                    'plugin.debug',
                    {plugin = {name = pluginDir, version = 'undefined'}, message = 'plugin disabled in plugin.cfg'}
                )
                break
            end
            local AutoLoad = (pluginConfig.AutoLoad and pluginConfig.AutoLoad['enabled'] == 'true') or false;
            local AutoLoadPriority = (pluginConfig.AutoLoad and pluginConfig.AutoLoad['priority']) or 999;

            if validPluginConfig(pluginConfig) then
                table.insert(
                    pluginsToLoad, {
                        name = pluginConfig.name,
                        priority = AutoLoadPriority,
                        autoLoad = AutoLoad,
                        path = FS.joinpath(path, pluginDir),
                        config = pluginConfig,
                    }
                )
            end
        end
    end

    -- order plugins by priority
    table.sort(pluginsToLoad, function(a, b) return a.priority > b.priority end)

    -- load plugins
    table.ForArr(
        pluginsToLoad, function(plugin, i)
            local pluginFilePath = FS.joinpath(plugin.path, 'plugin.lua')
            local AutoLoad = plugin.autoLoad
            local pluginName = plugin.name
            local pluginConfig = plugin.config
            local pluginVersion = pluginConfig.version

            --- try to autoLoad this plugin
            if AutoLoad then
                --- plugin.lua must exist
                if (FS.isFile(pluginFilePath)) then
                    local success, message = self:loadPlugin(pluginName, pluginFilePath, pluginConfig)
                    if not success then
                        self.events:emit(
                            'plugin.error', {
                                plugin = {name = pluginName, version = (pluginVersion or 'undefined')},
                                error = (message or 'failed loading plugin, unknown error'),
                            }
                        )
                        return
                    end
                    self.events:emit(
                        'plugin.load', {
                            plugin = {name = pluginName, version = (pluginVersion or 'undefined')},
                            message = (message or 'plugin loaded successfully'),
                        }
                    )
                    return
                else
                    self.events:emit(
                        'plugin.error', {
                            plugin = {name = pluginName, version = (pluginVersion or 'undefined')},
                            error = 'failed loading plugin, plugin.lua does not exist',
                        }
                    )
                    return
                end
            end
        end
    )
end

--- unload a plugin
--- @param name string the name of the plugin to unload
--- @return boolean unloaded if unloaded successfuly, false if error or not found
function plugin_manager:unloadPlugin(name, ...)
    for i, plugin in ipairs(self.plugins) do
        if (type(plugin['plugin']) ~= 'table') then break end
        local this = plugin['plugin']
        if this.name == name then
            table.remove(self.plugins, i)
            if type(this.onUnload) == 'function' then
                --- verify that the plugin unloaded successfully using pcalls
                local status, message = pcall(this.onUnload, ...);
                if not status then
                    self.events:emit(
                        'plugin.error',
                        {plugin = {name = name, version = (this.version or 'undefined')}, error = message or 'unknown error'}
                    )
                    return false, message
                end
                self.events:emit(
                    'plugin.unload', {
                        plugin = {name = name, version = (this.version or 'undefined')},
                        message = (message or 'plugin unloaded successfully'),
                    }
                )
                return status, (message or 'plugin unloaded successfully')
            end
            local msg = 'plugin removed but no onUnload method found, so couldnt check unloaded state (this is not an error)'
            self.events:emit('plugin.unload', {plugin = {name = name, version = (this.version or 'undefined')}, message = msg})
            return true, msg
        end
    end
    return false
end

--- List all plugins
---@return table<string, table> pluginInfo a table of info about loaded plugins
function plugin_manager:listPlugins()
    local plugin_list = {}
    for _, plugin in pairs(self.plugins) do
        if (type(plugin['plugin']) ~= 'table') then break end
        local this = plugin['plugin']
        local entry = {
            plugin_file = (plugin['path'] or 'unKnown'),
            plugin_description = (this['description'] or 'unKnown'),
            plugin_hasLoadMethod = (type(this['onLoad']) == 'function'),
            plugin_hasUnloadMethod = (type(this['onUnload']) == 'function'),
        }
        plugin_list[this.name] = entry
    end
    return plugin_list
end

--- Use a plugin, this takes a plugin name and optionally a callback function, which is called and passed any extra args.
--- If the callback function is provided, it is called with 2 defined args.
--- `pluginInfo` being the name,description etc
--- `plugin` this is your plugins `exports` table
--- any extra args passed to this function are passed to the callback function.
--- if the callback function returns a table, it is returned as the return value of this function.
--- if it returns `true,string` then it returns `true,string`
--- if it returns `false,string` the plugin is unloaded and the return value is `false, string`
--- all other return values are ignored and the plugin will continue.
---@param name 			string											plugin name
---@param callback 		fun(pluginInfo:table,plugin:MisModding.mPlugin,...)		callback function
---@vararg any															extra args
---@return any
function plugin_manager:use(name, callback, ...)
    local arg = {...};
    for _, entry in pairs(self.plugins) do
        local plugin = entry.plugin
        if plugin['name'] == name then
            if (type(callback) == 'function') then
                --- custom error handler for plugin  including its name and a stack trace
                local function pluginErrorHandler(err)
                    local trace = debug.traceback()
                    local msg = 'Error in plugin: ' .. plugin.name .. '\n' .. err .. '\n' .. trace
                    print(msg)
                    return false, msg
                end
                --- use xpcall to catch errors in the callback function
                local status, result = xpcall(
                                           function() return callback(plugin, plugin['exports'], unpack(arg)) end,
                                           pluginErrorHandler
                                       )
                --- handle the return
                if (status == false) then
                    self:unloadPlugin(plugin.name)
                    return false, result
                elseif status == true then
                    if (type(result) == 'table') then
                        -- if the callback returns a table, return it
                        return result
                    end
                    -- else return true and the result (usualy a message)
                    return true, result
                end
            end
            return plugin
        end
    end
end

--- used to set pluginManager initial config, this should not be called manualy.
---@param config table
---@return boolean  status: was the config set correctly.
---@return string   message: any message returned by setConfig.
function plugin_manager:setConfig(config)
    if (type(config) ~= 'table') then return false, 'config must be a table' end
    --- limit config to whats defined in the pluginOpts config table
    for key, value in pairs(pluginOpts) do
        if config[key] ~= nil then
            --- use provided or default value
            self.Config[key] = (config[key] or value)
        end
    end

    return true
end

_G['g_PluginManager'] = plugin_manager()
return _G['g_PluginManager']
