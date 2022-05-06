local Class = require "ClassBuilder"
local FS = require('FileSystem')

local luaLoadFile = function(fPath)
    local file, script
    if fPath then
        file = io.open(fPath, 'r')
        if (not file) or (not file.read) then return false, string.format('failed to read from file: %s', fPath) end
        script = file:read('*a')
        file:close()
        if (not script) then return false, 'no file content' end
        return (function() return pcall(loadstring, script) end)()
    end
    return false, 'no path given'
end

---@class MisModding.mPlugin
---@field new 			fun(self:MisModding.mPlugin,pluginPath:string):boolean,MisModding.mPlugin 	initialise a new Plugin.
---@field source 		string 													                    raw plugin source (read from file).
---@field config 		table													                    plugin config.
---@field path 			string													                    plugin path.
---@field DependsOn 	table														                list of plugins this plugin depends on
---@field AutoLoadConf  table                                                                       plugins autoLoad config
local mPlugin = Class {}

function mPlugin:new(pluginPath, initialConfig)
    if assert_arg(1, pluginPath, 'string') then
        return nil, 'invalid pluginPath or no path given'
    elseif (not FS.isDir(pluginPath)) then
        return nil, string.expand('unknown or invalid path: ${path}', {path = pluginPath})
    end
    local pluginFile = FS.joinpath(pluginPath, 'plugin.lua')
    if (not FS.isFile(pluginFile)) then return nil, string.expand('failed to find pluginFile: ${file}', {file = pluginFile}) end
    local loaded, result = luaLoadFile(pluginFile)
    if (not loaded) then
        return false, string.expand('failed to compile plugin file: ${file} > ${result}',
                                    {file = pluginFile, result = tostring(result)})
    else
        local plugin = result()
        if (not plugin.name) then return false, 'no plugin name defined' end
        if (not plugin.description) then return false, 'no plugin description defined' end
        if (not plugin.version) then return false, 'no plugin version defined' end
        local sourceFile = FS.readfile(pluginFile)
        self.path = pluginFile
        self.source = sourceFile
        self.plugin = plugin
        self.DependsOn = {}
        if (not self.config) then self.config = {} end
        --- if we were given initialConfig, merge copy it into the plugin config
        if (initialConfig) then
            local updated, updateErr = self:setConfig(initialConfig)
            if (not updated) then return false, updateErr end
        end
    end
end

--- set plugin config
---@param config table
function mPlugin:setConfig(config)
    if assert_arg(1, config, 'table') then
        return false, 'config must be a table'
    end
    -- TODO: validate config
    table.ForEach(config, function(val,opt)
        --- config.AutoLoad maps to self.AutoLoad
        if opt == 'AutoLoad' then
            self.AutoLoadConf = val
            return
        end

        if opt == 'Dependencies' then
            if assert_arg(2, val, 'table') then
                return false, 'Dependencies must be a table'
            end
            
            table.ForEach(val, function(dependVersion,dependName)
                if assert_arg(2, dependVersion, 'string') then
                    return false, 'invalid dependency version'
                end
                if assert_arg(3, dependName, 'string') then
                    return false, 'invalid dependency name'
                end
                self.DependsOn[dependName] = dependVersion
            end)

            return
        end
        
        --- set all other config values
        self.config[opt] = val
    end)
    return true, 'config updated'
end

-- get plugin config
---@return table
function mPlugin:getConfig()
    return self.config
end

--- fetch the plugin source
function mPlugin:getSrc() return self.source end

--- fetch a list of plugins this plugin depends on
function mPlugin:getDepends() return self.DependsOn end

RegisterModule("MisModding.PluginManager.Classes.Plugin",mPlugin)
return mPlugin
