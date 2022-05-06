-- Copyright (C) 2022 Theros [MisModding|SvalTek]
-- 
-- This file is part of mPluginManager.
-- 
-- mPluginManager is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- mPluginManager is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with mPluginManager.  If not, see <http://www.gnu.org/licenses/>.
--[[
    ! mPluginManager Loader
]] local version = '1.0.0'

local defaultConfig = [[
config_version = 1.0.0

# Should PluginManager be Enabled, setting to False will disable all plugins
Enable = true

[Settings]
# Should we Enabled Debug Logging
Debug = false
# path to Plugins folder, relative to the main directory, default is "Plugins"
# in most cases this should be left as default, but if you have moved the plugin folder, you can change this value
PluginDir = "Plugins"
# in most cases this will not be used, but is important for correct functionality of a few external plugins.
# DO NOT CHANGE THIS VALUE UNLESS YOU KNOW WHAT YOU ARE DOING!
PubKEY = "31n023u23V123QCAWCAKWPWCOEIm0129"

[AutoLoad]
# Enable Plugin AutoLoad Feature, requires plugins have a plugin.cfg file in the root of the plugin directory
# the plugin.cfg file must contain and [AutoLoad] section with Enabled = true
Enabled = true
]]

-- load MisModding.Common
Script.ReloadScript 'MisModding/common.lua';
-- load common scripts/utils
Script.LoadScriptFolder 'MisModding/Common';

ServerOnly(
    function()
        -- load mPluginManager/main
        Script.ReloadScript 'MisModding/PluginManager/main.lua';

        local configReader = require 'configReader'; ---@type configReader
        local FS = require 'FileSystem'; ---@type Module.FileSystem

        --- check if the config file exists
        if not FS.isFile(FS.joinpath('.', 'pluginmanager.cfg')) then
            --- install our default config and create folder structure
            if not FS.isDir(FS.joinpath('.', 'Plugins')) then FS.mkDir(FS.joinpath('.', 'Plugins')); end
            FS.writefile(FS.joinpath('.', 'pluginmanager.cfg'), defaultConfig);
        end

        local config = configReader.read(
                           FS.joinpath('.', 'pluginmanager.cfg'), {smart = true, list_delim = ';', trim_quotes = true}
                       );
        if (config.Enabled == 'true') and (config.config_version == version) then
            --- set our loaded config.
            if config['Settings'] then g_PluginManager:setConfig(config['Settings']); end

            --- if defined set our AutoLoad Config.
            local AutoLoadConf
            if config['AutoLoad'] then
                AutoLoadConf = {
                    Enabled = config['AutoLoad'].Enabled == 'true',
                    PluginDir = config['Settings'].PluginDir or 'Plugins',
                };
            end

            g_PluginManager:autoLoadPlugins(AutoLoadConf);
        end
    end
);
