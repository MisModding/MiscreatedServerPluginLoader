-- Copyright (C) 2021 Theros [SvalTek|MisModding]
-- 
-- This file is part of mServerTools.
-- 
-- mServerTools is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- mServerTools is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with mServerTools.  If not, see <http://www.gnu.org/licenses/>.
---@diagnostic disable: undefined-global

local ClassBuilder = {}

do
    local _ENV = _ENV
    package.preload['ClassBuilder'] = function( ... )
        local arg = _G.arg;
        --
        -- ───────────────────────────────────────────────────────────── CLASSBUILDER ─────
        --
        -- Copyright (C) 2021 MisModding
        --
        -- 
        -- Miscord-Helper is free software: you can redistribute it and/or modify
        -- it under the terms of the GNU General Public License as published by
        -- the Free Software Foundation, either version 3 of the License, or
        -- (at your option) any later version.
        -- 
        -- Miscord-Helper is distributed in the hope that it will be useful,
        -- but WITHOUT ANY WARRANTY; without even the implied warranty of
        -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        -- GNU General Public License for more details.
        -- 
        -- You should have received a copy of the GNU General Public License
        -- along with Miscord-Helper.  If not, see <http://www.gnu.org/licenses/>.

        --- * Create a new Class
        ---@class ClassBuilder
        ---@type ClassBuilder|fun(classname:string,object:table):Class
        local Classy = {KnownClasses = {}}
        function Classy:Create( nameOrBase, base )
            ---@class Class
            local Object
            Object = {
                __index = {
                    Extend = function( self )
                        local obj = {super = self}
                        return setmetatable( obj, Object )
                    end,
                },
                __type = 'Class',
                __tostring = function( self ) return getmetatable( self ).__type end,
                __call = function( self, ... )
                    local obj = setmetatable( {}, { __index = self} )
                    if self['super'] and self.super['new'] then
                        self.super.new( obj, ... )
                    end
                    if self['new'] then self.new( obj, ... ) end
                    return obj
                end,
            }
            -- handle named classes
            if nameOrBase and (type( nameOrBase ) == 'string') then
                -- if the class exists, return it.
                if self.KnownClasses[nameOrBase] then
                    return self.KnownClasses[nameOrBase]
                else
                    -- set the Object type
                    Object.__type = nameOrBase

                    local obj = {}
                    -- populate class definition
                    if (type( base ) == 'table') then
                        for k,v in pairs( base ) do
                            obj[k] = v
                        end
                    end
                    setmetatable( obj, Object )
                    self.KnownClasses[nameOrBase] = obj
                    return obj
                end
            else
                local obj = {}
                if (type( nameOrBase ) == 'table') then
                    for k,v in pairs( nameOrBase ) do
                        obj[k] = v
                    end
                end
                return setmetatable( obj, Object ) ---@type Class
            end
        end

        local meta = {__call = function( self, ... ) return self:Create( ... ) end}

        setmetatable( Classy, meta )
        ---@type Class
        ClassBuilder = Classy
        return ClassBuilder
    end
end

do
    local _ENV = _ENV
    package.preload['FileSystem'] = function( ... )
        local arg = _G.arg;
        -- Copyright (C) 2021 MisModding
        -- 
        -- 
        -- Miscord-Helper is free software: you can redistribute it and/or modify
        -- it under the terms of the GNU General Public License as published by
        -- the Free Software Foundation, either version 3 of the License, or
        -- (at your option) any later version.
        -- 
        -- Miscord-Helper is distributed in the hope that it will be useful,
        -- but WITHOUT ANY WARRANTY; without even the implied warranty of
        -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        -- GNU General Public License for more details.
        -- 
        -- You should have received a copy of the GNU General Public License
        -- along with Miscord-Helper.  If not, see <http://www.gnu.org/licenses/>.

        ---@class Module.FileSystem
        local FS = {}

        --- return the contents of a file as a string
        -- @param filename The file path
        -- @param is_bin open in binary mode, default false
        -- @return file contents, or nil,error
        function FS.readfile( filename, is_bin )
            local mode = is_bin and 'b' or ''
            local f, err = io.open( filename, 'r' .. mode )
            if not f then return nil, err end
            local res, err = f:read( '*a' )
            f:close()
            if not res then return nil, err end
            return res
        end

        --- write a string to a file,
        -- @param filename The file path
        -- @param str The string
        -- @param is_bin open in binary mode, default false
        -- @return true or nil,error
        function FS.writefile( filename, str, is_bin )
            local f, err = io.open( filename, 'w' .. (is_bin or '') )
            if not f then return nil, err end
            f:write( str )
            f:close()
            return true
        end

        --- Read a file into a list of lines and close it.
        -- @param h file handle or name (default: <code>io.input ()</code>)
        -- @return list of lines
        function FS.readlines( h )
            if h == nil then
                h = io.input()
            elseif _G.type( h ) == 'string' then
                h = io.open( h )
            end
            local l = {}
            for line in h:lines() do table.insert( l, line ) end
            h:close()
            return l
        end

        --- Write values adding a newline after each.
        -- @param h file handle (default: <code>io.output ()</code>
        -- @param ... values to write (as for write)
        function FS.writeline( h, ... )
            if io.type( h ) ~= 'file' then
                io.write( h, '\n' )
                h = io.output()
            end
            for _, v in ipairs( {...} ) do h:write( v, '\n' ) end
        end

        local separator = '/'

        --- Strip the path off a path+filename.
        -- @param pathname string: A path+name, such as "/a/b/c"
        -- or "\a\b\c".
        -- @return string: The filename without its path, such as "c".
        function FS.base_name( pathname )
            local base = pathname:match( '.*[/\\]([^/\\]*)' )
            return base or pathname
        end

        --- Strip the name off a path+filename.
        -- @param pathname string: A path+name, such as "/a/b/c".
        -- @return string: The filename without its path, such as "/a/b/".
        -- For entries such as "/a/b/", "/a/" is returned. If there are
        -- no directory separators in input, "" is returned.
        function FS.dir_name( pathname )
            return (pathname:gsub( '/*$', '' ):match( '(.*/)[^/]*' )) or ''
        end

        function FS.strip_base_dir( pathname ) return pathname:gsub( '^[^/]*/', '' ) end

        local sep, other_sep = '\\', '/'

        --- split a path into directory and file part.
        -- if there's no directory part, the first value will be the empty string.
        -- Handles both forward and back-slashes on Windows.
        -- @param P A file path
        -- @return the directory part
        -- @return the file part
        function FS.splitpath( P )
            local i = #P
            local ch = P:sub( i, i )
            while i > 0 and ch ~= sep and ch ~= other_sep do
                i = i - 1
                ch = P:sub( i, i )
            end
            if i == 0 then
                return '', P
            else
                return P:sub( 1, i - 1 ), P:sub( i + 1 )
            end
        end

        --- split a path into root and extension part.
        -- if there's no extension part, the second value will be empty
        -- @param P A file path
        -- @return the name part
        -- @return the extension
        function FS.splitext( P )
            local i = #P
            local ch = P:sub( i, i )
            while i > 0 and ch ~= '.' do
                if ch == sep or ch == other_sep then return P, '' end
                i = i - 1
                ch = P:sub( i, i )
            end
            if i == 0 then
                return P, ''
            else
                return P:sub( 1, i - 1 ), P:sub( i )
            end
        end

        local PathSep = separator
        --- Describe a path
        -- uses the current systems defined seperator
        -- @param ... strings representing directories
        -- @return string: a string with a platform-specific representation
        -- of the path.
        function FS.joinpath( ... )
            local path = ''
            for i, segment in ipairs( {...} ) do
                if PathSep ~= '/' then segment = segment:gsub( [[\]], '/' ) end
                if i == 1 then
                    path = segment
                else
                    path = path .. '/' .. segment
                end
            end
            return string.gsub( path, '/+', '/' )
        end

        function FS.isFile( path )
            local f = io.open( path, 'r' )
            if f then
                f:close()
                return true
            end
            return false
        end
        -- Check if a directory exists path
        function FS.isDir( path )
            path = string.gsub( path .. '/', '//', '/' )
            local ok, err, code = os.rename( path, path )
            if ok or code == 13 then return true end
            return false
        end

        function FS.mkDir( path )
            local ok, Result = os.execute( 'mkdir ' .. path:gsub( '/', '\\' ) )
            if not ok then
                return nil, 'Failed to Create ' .. path .. ' Directory! - ' .. Result
            else
                return true, 'Successfully Created ' .. path .. ' Directory!'
            end
        end

        --- Write a Table as JSON file to Disk
        --- @param path string       path of file to Write, starts in Server root
        --- @param data any          File Contents to Write
        --- @return boolean,string   true/nil and a message
        function FS.WriteJSON( path, data )
            local JSON = require( 'JSON' )
            local thisFile = assert( io.open( path, 'w' ) )
            if thisFile ~= nil then
                local fWritten = thisFile:write( JSON.stringify( data ) )
                thisFile:close()
                if fWritten ~= nil then
                    return true, 'Success Writing File: <ServerRoot>/' .. path
                else
                    return nil, 'Failed to Write Data to File: <ServerRoot>/' .. path
                end
            else
                return nil, 'Failed to Open file for Writing: <ServerRoot>/' .. path
            end
        end

        --- Read JSON File as Table from Disk
        --- @param path string      path of file to Write, starts in Server root
        --- @return boolean,any     true/nil and file content or message
        function FS.ReadJSON( path )
            local JSON = require( 'JSON' )
            local thisFile, errMsg = io.open( path, 'r' )
            if thisFile ~= nil then
                local fContent = thisFile:read( '*all' )
                thisFile:close()
                if fContent ~= '' or nil then
                    return true, JSON.parse( fContent )
                else
                    return nil, 'Failed to Read from File: ' .. path
                end
            else
                return nil, 'Error Opening file: ' .. path .. ' io.open returned:' .. errMsg
            end
        end

        return FS
    end
end

do
    local _ENV = _ENV
    package.preload['Hooker'] = function( ... )
        local arg = _G.arg;
        -- Updated: 2021 MisModding
        --
        -- EntranceJew made this.
        -- https://github.com/EntranceJew/hooker

        ---@class Module.Hooker
        local hooker = {
            hookTable = {},
            hookIter = pairs,
            -- override this if you want globally deterministic hook iteration
        }
        -- this is where we store our hooks and the things that latch on to them like greedy little hellions

        local function pack( ... ) return {n = select( '#', ... ), ...} end

        function hooker.Add( eventName, identifier, func )
            -- string, any, function
            if hooker.hookTable[eventName] == nil then hooker.hookTable[eventName] = {} end
            hooker.hookTable[eventName][identifier] = func
        end

        function hooker.Call( eventName, ... )
            -- string, varargs
            if hooker.hookTable[eventName] == nil then
                -- skip processing the hook because nobody's listening
                return nil
            else
                local results
                for identifier, func in hooker.hookIter( hooker.hookTable[eventName] ) do
                    results = pack( func( ... ) )
                    results.n = nil
                    if #results > 0 then
                        -- potential problems if relying on sandwiching a nil in the return results
                        return unpack( results )
                    end
                end
            end
        end

        function hooker.GetTable() return hooker.hookTable end

        function hooker.Remove( eventName, identifier )
            --[[string, string]]
            if hooker.hookTable[eventName] == nil or hooker.hookTable[eventName][identifier] == nil then
                return false
            else
                hooker.hookTable[eventName][identifier] = nil
            end
            -- see if the table is empty and nil it for the benefit of hook.Call's optimization
            for k, v in pairs( hooker.hookTable[eventName] ) do
                -- we found something, exit the function
                return true
            end
            -- if we reach this far then the table must've been empty
            hooker.hookTable[eventName] = nil
            return true
        end

        return hooker
    end
end

do
    local _ENV = _ENV
    package.preload['JSON'] = function( ... )
        local arg = _G.arg;

        ---@class Module.JSON
        local json = {}

        -- Internal functions.

        local function kind_of( obj )
            if type( obj ) ~= 'table' then return type( obj ) end
            local i = 1
            for _ in pairs( obj ) do
                if obj[i] ~= nil then
                    i = i + 1
                else
                    return 'table'
                end
            end
            if i == 1 then
                return 'table'
            else
                return 'array'
            end
        end

        local function escape_str( s )
            local in_char = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
            local out_char = {'\\', '"', '/', 'b', 'f', 'n', 'r', 't'}
            for i, c in ipairs( in_char ) do s = s:gsub( c, '\\' .. out_char[i] ) end
            return s
        end

        -- Returns pos, did_find; there are two cases:
        -- 1. Delimiter found: pos = pos after leading space + delim; did_find = true.
        -- 2. Delimiter not found: pos = pos after leading space;     did_find = false.
        -- This throws an error if err_if_missing is true and the delim is not found.
        local function skip_delim( str, pos, delim, err_if_missing )
            pos = pos + #str:match( '^%s*', pos )
            if str:sub( pos, pos ) ~= delim then
                if err_if_missing then
                    error( 'Expected ' .. delim .. ' near position ' .. pos )
                end
                return pos, false
            end
            return pos + 1, true
        end

        -- Expects the given pos to be the first character after the opening quote.
        -- Returns val, pos; the returned pos is after the closing quote character.
        local function parse_str_val( str, pos, val )
            val = val or ''
            local early_end_error = 'End of input found while parsing string.'
            if pos > #str then error( early_end_error ) end
            local c = str:sub( pos, pos )
            if c == '"' then return val, pos + 1 end
            if c ~= '\\' then return parse_str_val( str, pos + 1, val .. c ) end
            -- We must have a \ character.
            local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
            local nextc = str:sub( pos + 1, pos + 1 )
            if not nextc then error( early_end_error ) end
            return parse_str_val( str, pos + 2, val .. (esc_map[nextc] or nextc) )
        end

        -- Returns val, pos; the returned pos is after the number's final character.
        local function parse_num_val( str, pos )
            local num_str = str:match( '^-?%d+%.?%d*[eE]?[+-]?%d*', pos )
            local val = tonumber( num_str )
            if not val then error( 'Error parsing number at position ' .. pos .. '.' ) end
            return val, pos + #num_str
        end

        -- Public values and functions.

        function json.stringify( obj, as_key )
            local s = {} -- We'll build the string as an array of strings to be concatenated.
            local kind = kind_of( obj ) -- This is 'array' if it's an array or type(obj) otherwise.
            if kind == 'array' then
                if as_key then error( 'Can\'t encode array as key.' ) end
                s[#s + 1] = '['
                for i, val in ipairs( obj ) do
                    if i > 1 then s[#s + 1] = ', ' end
                    s[#s + 1] = json.stringify( val )
                end
                s[#s + 1] = ']'
            elseif kind == 'table' then
                if as_key then error( 'Can\'t encode table as key.' ) end
                s[#s + 1] = '{'
                for k, v in pairs( obj ) do
                    if #s > 1 then s[#s + 1] = ', ' end
                    s[#s + 1] = json.stringify( k, true )
                    s[#s + 1] = ':'
                    s[#s + 1] = json.stringify( v )
                end
                s[#s + 1] = '}'
            elseif kind == 'string' then
                return '"' .. escape_str( obj ) .. '"'
            elseif kind == 'number' then
                if as_key then return '"' .. tostring( obj ) .. '"' end
                return tostring( obj )
            elseif kind == 'boolean' then
                return tostring( obj )
            elseif kind == 'nil' then
                return 'null'
            else
                error( 'Unjsonifiable type: ' .. kind .. '.' )
            end
            return table.concat( s )
        end

        json.null = {} -- This is a one-off table to represent the null value.

        function json.parse( str, pos, end_delim )
            pos = pos or 1
            if pos > #str then error( 'Reached unexpected end of input.' ) end
            local pos = pos + #str:match( '^%s*', pos ) -- Skip whitespace.
            local first = str:sub( pos, pos )
            if first == '{' then -- Parse an object.
                local obj, key, delim_found = {}, true, true
                pos = pos + 1
                while true do
                    key, pos = json.parse( str, pos, '}' )
                    if key == nil then return obj, pos end
                    if not delim_found then
                        error( 'Comma missing between object items.' )
                    end
                    pos = skip_delim( str, pos, ':', true ) -- true -> error if missing.
                    obj[key], pos = json.parse( str, pos )
                    pos, delim_found = skip_delim( str, pos, ',' )
                end
            elseif first == '[' then -- Parse an array.
                local arr, val, delim_found = {}, true, true
                pos = pos + 1
                while true do
                    val, pos = json.parse( str, pos, ']' )
                    if val == nil then return arr, pos end
                    if not delim_found then
                        error( 'Comma missing between array items.' )
                    end
                    arr[#arr + 1] = val
                    pos, delim_found = skip_delim( str, pos, ',' )
                end
            elseif first == '"' then -- Parse a string.
                return parse_str_val( str, pos + 1 )
            elseif first == '-' or first:match( '%d' ) then -- Parse a number.
                return parse_num_val( str, pos )
            elseif first == end_delim then -- End of an object or array.
                return nil, pos + 1
            else -- Parse true, false, or null.
                local literals = {['true'] = true, ['false'] = false, ['null'] = json.null}
                for lit_str, lit_val in pairs( literals ) do
                    local lit_end = pos + #lit_str - 1
                    if str:sub( pos, lit_end ) == lit_str then
                        return lit_val, lit_end + 1
                    end
                end
                local pos_info_str = 'position ' .. pos .. ': ' .. str:sub( pos, pos + 10 )
                error( 'Invalid json syntax starting at ' .. pos_info_str )
            end
        end

        return json
    end
end

do
    local _ENV = _ENV
    package.preload['Logger'] = function( ... )
        local arg = _G.arg;
        -- Copyright (C) 2021 MisModding
        -- 
        -- This file is part of Miscord-Helper.
        -- 
        -- Miscord-Helper is free software: you can redistribute it and/or modify
        -- it under the terms of the GNU General Public License as published by
        -- the Free Software Foundation, either version 3 of the License, or
        -- (at your option) any later version.
        -- 
        -- Miscord-Helper is distributed in the hope that it will be useful,
        -- but WITHOUT ANY WARRANTY; without even the implied warranty of
        -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        -- GNU General Public License for more details.
        -- 
        -- You should have received a copy of the GNU General Public License
        -- along with Miscord-Helper.  If not, see <http://www.gnu.org/licenses/>.

        ---create a new simple logger
        ---@param name string
        ---@param path string
        ---@param level number
        ---@return simple_logger|boolean simple_logger instance or false
        ---@return nil|string error message
        local function CreateSimpleLogger( name, path, level )
            if assert_arg( 1, name, 'string' ) then
                return false, 'invalid Log name - Must be a String'
            end
            if assert_arg( 2, path, 'string' ) then
                return false, 'invalid Log file path - Must be a String'
            end
            if (level == nil) then
                level = 1
            else
                if assert_arg( 3, level, 'number' ) then
                    return false, 'invalid Log Level - Must be a Number'
                end
            end

            ---@class simple_logger
            ---@type fun( name:string, path:string, logLevel:number ):simple_logger
            local logger = {
                LOG_NAME = name,
                --- Path to File this Logger Writes to.
                LOG_FILE = path,
                --- this Loggers cuurrent Log Level
                LOG_LEVEL = level,
            }

            local template = [[ ${name} [${level}:${prefix}] >> 
                ${content}"]]

            local logfile = {
                path = logger.LOG_FILE,
                update = function( self, line )
                    local file = io.open( self.path, 'a+' )
                    if file then
                        file:write( line .. '\n' )
                        file:close()
                        return true, 'updated'
                    end
                    return false, 'failed to update file: ', (self.path or 'invalid path')
                end,
                purge = function( self ) os.remove( self.path ) end,
            }

            local function isDebug()
                local dbg = false
                if (System.GetCVar( 'log_verbosity' ) == 3) then
                    dbg = true
                elseif (logger.LOG_LEVEL >= 3) then
                    dbg = true
                end
                return dbg
            end

            local function writer( logtype, source, message )
                local logname = logger['LOG_NAME'] or 'Logger'
                local line = string.expand( template, {
                    name = logname,
                    level = logtype,
                    prefix = source,
                    content = message,
                } )
                return logfile:update( os.date() .. '  >> ' .. line )
            end

            --- Writes a [Log] level entry to the mFramework log
            logger.Log = function( source, message )
                if not (logger.LOG_LEVEL >= 1) then return end
                return writer( 'LOG', source, message )
            end

            --- Writes a [Error] level entry to the mFramework log
            logger.Error = function( source, message )
                if not (logger.LOG_LEVEL >= 1) then return end
                return writer( 'ERROR', source, message )
            end

            --- Writes a [Warning] level entry to the mFramework log
            logger.Warn = function( source, message )
                if not (logger.LOG_LEVEL >= 2) then return end
                return writer( 'WARNING', source, message )
            end
            --- Writes a [Debug] level entry to the mFramework log
            logger.Debug = function( source, message )
                if not isDebug() then return end
                return writer( 'DEBUG', source, message )
            end

            logfile:purge()
            return logger
        end

        return CreateSimpleLogger
    end
end

do
    local _ENV = _ENV
    package.preload['MisDB2'] = function( ... )
        local arg = _G.arg;
        -- ---------------------------------------------------------------------------------------------- --
        --                                            ~ MisDB ~                                           --
        -- ---------------------------------------------------------------------------------------------- --
        --[[
    MisDB Provides Mods With a Method for "Data Persistance"
    Via JSON File Backed "Pages" and "Collections".
    Based on a Module to Providing a "Pure Lua" implementation
    'Similar' to flatDB/NoDB
    
    MisDB Takes a Lua Table Converts it to JSON, and we call that a "Page"
    These "Pages" are Grouped into Named "Collections" and Stored as Seperate Files,
    One for Each Different Collection in a Folder with this "MisDB Objects" Name
    And Placed in the Specified Base Directory (Relative to Your Server Root)
    eg:
    
    For a MisDB Called "MyModsData" with a Collection Named "Settings"
    and Stored in the BaseDir "MisDBdata" :
        [ServerRoot]>{BaseDir}/{MisDB Name}/{Collection Name}
            ServerRoot>/MisDBdata/MyModsData/Settings
    
    
    Methods:
    
    *    MisDB:Create(BaseDir, Name) ~> TableObject(Your Main MisDB Object)
            Creates a New MisDB Object to Store Collections Backed by files in
            [ServerRoot]>{BaseDir}/{Name}
    
    With the Returned {Object} then:
    *    {Object}:Collection(Name) ~> CollectionObject(Table/Object defining this Collection)
            Create/Fetch a New Collection in this MisDB (Non Existant Collections Are autoCreated)
    
    the Returned {Collection} then provides the following Methods:
    *    {Collection}:GetPage(pageId)
            Fetch The Contents of a "Page" from this "Collection" By Specified PageID
            ! This Will return nil, with a message as the Second return var if the Page Does Not Exist
    *    {Collection}:SetPage(pageId,data)
            Set The Contents of a "Page" from this "Collection" By Specified PageID
            ? Returns the "written to disk" Copy of the Page Content you Set
            ? Use this to save your page data and use the return to verify against your data
    *    {Collection}:PurgePage(pageId)
            Remove a "Page" from this "Collection" By Specified PageID
            ? returns true/nil and a message with the result
    
    ]]
        local pathseparator = package.config:sub( 1, 1 );
        function getPath( ... )
            local elements = {...}
            return table.concat( elements, pathseparator )
        end
        local function isFile( path )
            local f = io.open( path, 'r' )
            if f then
                f:close()
                return true
            end
            return false
        end
        local function isDir( path )
            path = string.gsub( path .. '/', '//', '/' )
            local ok, err, code = os.rename( path, path )
            if ok or code == 13 then return true end
            return false
        end
        local function mkDir( path )
            local ok, Result = os.execute( 'mkdir ' .. path:gsub( '/', '\\' ) )
            if not ok then
                return nil, 'Failed to Create ' .. path .. ' Directory! - ' .. Result
            else
                return true, 'Successfully Created ' .. path .. ' Directory!'
            end
        end
        local function MakeClass( Object )
            return ClassBuilder(Object)
        end
        local json = {}
        -- Internal functions.
        local function kind_of( obj )
            if type( obj ) ~= 'table' then return type( obj ) end
            local i = 1
            for _ in pairs( obj ) do
                if obj[i] ~= nil then
                    i = i + 1
                else
                    return 'table'
                end
            end
            if i == 1 then
                return 'table'
            else
                return 'array'
            end
        end

        local function escape_str( s )
            local in_char = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
            local out_char = {'\\', '"', '/', 'b', 'f', 'n', 'r', 't'}
            for i, c in ipairs( in_char ) do s = s:gsub( c, '\\' .. out_char[i] ) end
            return s
        end

        -- Returns pos, did_find; there are two cases:
        -- 1. Delimiter found: pos = pos after leading space + delim; did_find = true.
        -- 2. Delimiter not found: pos = pos after leading space;     did_find = false.
        -- This throws an error if err_if_missing is true and the delim is not found.
        local function skip_delim( str, pos, delim, err_if_missing )
            pos = pos + #str:match( '^%s*', pos )
            if str:sub( pos, pos ) ~= delim then
                if err_if_missing then
                    error( 'Expected ' .. delim .. ' near position ' .. pos )
                end
                return pos, false
            end
            return pos + 1, true
        end

        -- Expects the given pos to be the first character after the opening quote.
        -- Returns val, pos; the returned pos is after the closing quote character.
        local function parse_str_val( str, pos, val )
            val = val or ''
            local early_end_error = 'End of input found while parsing string.'
            if pos > #str then error( early_end_error ) end
            local c = str:sub( pos, pos )
            if c == '"' then return val, pos + 1 end
            if c ~= '\\' then return parse_str_val( str, pos + 1, val .. c ) end
            -- We must have a \ character.
            local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
            local nextc = str:sub( pos + 1, pos + 1 )
            if not nextc then error( early_end_error ) end
            return parse_str_val( str, pos + 2, val .. (esc_map[nextc] or nextc) )
        end

        -- Returns val, pos; the returned pos is after the number's final character.
        local function parse_num_val( str, pos )
            local num_str = str:match( '^-?%d+%.?%d*[eE]?[+-]?%d*', pos )
            local val = tonumber( num_str )
            if not val then error( 'Error parsing number at position ' .. pos .. '.' ) end
            return val, pos + #num_str
        end

        -- Public values and functions.

        function json.stringify( obj, as_key )
            local s = {} -- We'll build the string as an array of strings to be concatenated.
            local kind = kind_of( obj ) -- This is 'array' if it's an array or type(obj) otherwise.
            if kind == 'array' then
                if as_key then error( 'Can\'t encode array as key.' ) end
                s[#s + 1] = '['
                for i, val in ipairs( obj ) do
                    if i > 1 then s[#s + 1] = ', ' end
                    s[#s + 1] = json.stringify( val )
                end
                s[#s + 1] = ']'
            elseif kind == 'table' then
                if as_key then error( 'Can\'t encode table as key.' ) end
                s[#s + 1] = '{'
                for k, v in pairs( obj ) do
                    if #s > 1 then s[#s + 1] = ', ' end
                    s[#s + 1] = json.stringify( k, true )
                    s[#s + 1] = ':'
                    s[#s + 1] = json.stringify( v )
                end
                s[#s + 1] = '}'
            elseif kind == 'string' then
                return '"' .. escape_str( obj ) .. '"'
            elseif kind == 'number' then
                if as_key then return '"' .. tostring( obj ) .. '"' end
                return tostring( obj )
            elseif kind == 'boolean' then
                return tostring( obj )
            elseif kind == 'nil' then
                return 'null'
            else
                error( 'Unjsonifiable type: ' .. kind .. '.' )
            end
            return table.concat( s )
        end

        json.null = {} -- This is a one-off table to represent the null value.

        function json.parse( str, pos, end_delim )
            pos = pos or 1
            if pos > #str then error( 'Reached unexpected end of input.' ) end
            local pos = pos + #str:match( '^%s*', pos ) -- Skip whitespace.
            local first = str:sub( pos, pos )
            if first == '{' then -- Parse an object.
                local obj, key, delim_found = {}, true, true
                pos = pos + 1
                while true do
                    key, pos = json.parse( str, pos, '}' )
                    if key == nil then return obj, pos end
                    if not delim_found then
                        error( 'Comma missing between object items.' )
                    end
                    pos = skip_delim( str, pos, ':', true ) -- true -> error if missing.
                    obj[key], pos = json.parse( str, pos )
                    pos, delim_found = skip_delim( str, pos, ',' )
                end
            elseif first == '[' then -- Parse an array.
                local arr, val, delim_found = {}, true, true
                pos = pos + 1
                while true do
                    val, pos = json.parse( str, pos, ']' )
                    if val == nil then return arr, pos end
                    if not delim_found then
                        error( 'Comma missing between array items.' )
                    end
                    arr[#arr + 1] = val
                    pos, delim_found = skip_delim( str, pos, ',' )
                end
            elseif first == '"' then -- Parse a string.
                return parse_str_val( str, pos + 1 )
            elseif first == '-' or first:match( '%d' ) then -- Parse a number.
                return parse_num_val( str, pos )
            elseif first == end_delim then -- End of an object or array.
                return nil, pos + 1
            else -- Parse true, false, or null.
                local literals = {['true'] = true, ['false'] = false, ['null'] = json.null}
                for lit_str, lit_val in pairs( literals ) do
                    local lit_end = pos + #lit_str - 1
                    if str:sub( pos, lit_end ) == lit_str then
                        return lit_val, lit_end + 1
                    end
                end
                local pos_info_str = 'position ' .. pos .. ': ' .. str:sub( pos, pos + 10 )
                error( 'Invalid json syntax starting at ' .. pos_info_str )
            end
        end

        
        --- MisDB2 Main Object
        ---@type fun(dbName:string):MisDB2
        ---@class MisDB2
        ---@field data_hook_read fun(data:any):data handles data mutation when reading from disk can be used to modify the data before it is returned
        ---@field data_hook_write fun(data:any):data handles data mutation before writing to disk can be overriden
        local MisDB = ClassBuilder ('MisDB2',{
            data_hook_read = function( data ) return json.parse( data ) end,
            data_hook_write = function( data ) return json.stringify( data ) end,
        }) ---@type MisDB2

        local function load_page( path )
            local ret
            local f = io.open( path, 'rb' )
            if f then
                ret = MisDB.data_hook_read( f:read( '*a' ) )
                f:close()
            end
            return ret
        end
        local function store_page( path, page )
            if page then
                local f = io.open( path, 'wb' )
                if f then
                    f:write( MisDB.data_hook_write( page ) )
                    f:close()
                    return true
                end
            end
            return false
        end

        local pool = {}

        local db_funcs = {
            save = function( db, p )
                if p then
                    if (type( p ) == 'string') and db[p] then
                        return store_page( pool[db] .. '/' .. p, db[p] )
                    else
                        return false
                    end
                end
                for p, page in pairs( db ) do
                    if not store_page( pool[db] .. '/' .. p, page ) then
                        return false
                    end
                end
                return true
            end,
        }
        local mt = {
            __index = function( db, k )
                if db_funcs[k] then return db_funcs[k] end
                if isFile( pool[db] .. '/' .. k ) then
                    db[k] = load_page( pool[db] .. '/' .. k )
                end
                return rawget( db, k )
            end,
        }
        pool.hook = db_funcs
        local dbcontroller = setmetatable( pool, {
            __mode = 'kv',
            __call = function( pool, path )
                assert( isDir( path ), path .. ' is not a directory.' )
                if pool[path] then return pool[path] end
                local db = {}
                setmetatable( db, mt )
                pool[path] = db
                pool[db] = path
                return db
            end,
        } )

        function MisDB:new( baseDir )
            if (not baseDir) then return false, 'invalid basedir' end
            local dbDir = getPath( './MisDB_Data', baseDir )
            self.baseDir = dbDir
            if (not isDir( dbDir )) then mkDir( dbDir ) end
            self.Collections = {}
        end

        ---@class MisDB2.Collection
        ---@type fun(name:string):MisDB2.Collection
        local collection = {}

        function collection:new( source ) self.data = (source or {}) end

        function collection:GetPage( pageId )
            local data = self.data[pageId]
            if (data == nil) or (data == json.null) then
                return false, 'no page data for pageId:' .. pageId
            end
            return self.data[pageId]
        end

        function collection:SetPage( pageId, data )
            self.data[pageId] = (data or json.null)
            self.data:save()
            local dataRead, error = self:GetPage( pageId )
            if dataRead then
                if dataRead == data then
                    return true, 'Page Data updated'
                else
                    return false, 'failed to update Page Data: ' .. error
                end
            end
            return false, 'failed to verify Page Data'
        end

        function collection:Save( pageId ) return self.data:save( pageId ) end

        local Collection = MakeClass( collection )

        function MisDB:Collection( name )
            if not self.Collections[name] then
                local collectionDir = getPath( self.baseDir, name )
                if not isDir( collectionDir ) then mkDir( collectionDir ) end
                self.Collections[name] = dbcontroller( getPath( self.baseDir, name ) )
            end
            return Collection( self.Collections[name] )
        end

        ---@class MisDB2.DataStore_Opts
        ---@field name string name this DataStore
        ---@field persistance_dir string base directory for this DataStore

        ---@type fun(config:MisDB2.DataStore_Opts):MisDB2.DataStore
        ---@class MisDB2.DataStore
        ---@field DataSource table
        ---@field new fun(self:MisDB2.DataStore,config:MisDB2.DataStore_Opts):MisDB2.DataStore
        local DataStore = ClassBuilder("MisDB2.DataStore", {})
        ---* Defines a MisDB Backed Key/Value storage

        ---* DataStore(config)
        -- Create a New DataStore
        ---@param config table Config
        ---@usage
        --      local MisDB = require 'MisDB2' ---@type MisDB2
        --      local DataStore = MisDB.DataStore
        --      local MyClass = Class {}
        --      function MyClass:new()
        --          ---@type MisDB2.DataStore
        --          self.DataStore = DataStore {name = 'DataStoreName', persistance_dir = 'dataDir'}
        --      end
        function DataStore:new( config )
            if not type( config ) == 'table' then
                return nil, 'you must provide a DataStore config'
            elseif not config['persistance_dir'] then
                return nil, 'must specify persistance_dir'
            elseif not config['name'] then
                return nil, 'must specify a name'
            end
            self.DataSource = {
                Source = MisDB( config.persistance_dir ), ---@type MisDB2
            }
            self.DataSource['Data'] = self.DataSource['Source']:Collection( config.name ) ---@type MisDB2_Collection
            return self
        end
        ---* Fetches a Value from this DataStore
        ---@param key string ConfigKey
        ---@return number|string|table|boolean ConfigValue
        function DataStore:GetValue( key )
            local Cache = (self.DataSource['Data'] or {})
            return Cache.data[key]
        end
        ---* Saves a Value to this DataStore
        ---@param key string ConfigKey
        ---@param value number|string|table|boolean Value
        ---@return boolean Successfull
        function DataStore:SetValue( key, value )
            local Cache = (self.DataSource['Data'] or {})
            Cache.data[key] = value
            res = self.DataSource.Data:Save()
            return res
        end

        MisDB.DataStore = DataStore

        return MisDB
    end
end

do
    local _ENV = _ENV
    package.preload['Namespace'] = function( ... )
        local arg = _G.arg;
        -- Namespace support for Lua. By Andi McClure. Version 1.1
        --
        -- Suggested usage: At the top of your entry point file, say
        --     namespace = require "namespace"
        -- In any file thereafter, say
        --     namespace "somenamespace"
        -- And globals will be shared between only those files using the same key.
        --
        -- See comments on functions for more esoteric usages.

        local namespace_mt = {}
        local namespace = {}
        namespace_mt.__index = namespace
        local namespace_return = setmetatable( {}, namespace_mt )
        namespace.spaces = {} -- Named namespaces
        local origin
        local preload = {}

        local function table_clone( t )
            local out = {}
            for k, v in pairs( t ) do out[k] = v end
            return out
        end

        -- Get the table that a particular named namespace is stored in.
        -- If the namespace doesn't exist, one will be created and registered.
        -- Pass nil for name to get a unique single-use namespace.
        -- Pass a table or string (namespace name) for "inherit" to set the default values when creating a new namespace.
        function namespace.space( name, inherit )
            local space = name and namespace.spaces[name]
            if not space then
                -- Handle prepare()
                local preload_inherit, preload_construct
                if preload[name] then
                    preload_inherit, preload_construct = unpack( preload[name] )
                    preload[name] = nil
                    if preload_inherit then
                        if inherit and inherit ~= preload_inherit then
                            error( string.format(
                                     'Namespace "%s" given conflicting inherit instructions: "%s" in prepare() and "%s" later',
                                     name, preload_inherit, inherit ) )
                        end
                        inherit = preload_inherit
                    end
                end

                -- "inherit" could be one of several types right now. change it to a table.
                if type( inherit ) == 'string' then
                    local inherit_table = namespace.spaces[inherit]
                    if not inherit_table then
                        if preload[inherit] then -- Handle prepare()
                            inherit_table = namespace.space( inherit )
                        else
                            error( string.format(
                                     'Namespace "%s" tried to inherit from namespace "%s", but that doesn\'t exist',
                                     name, inherit ) )
                        end
                    end
                    inherit = inherit_table
                elseif not inherit then -- No inherit specified, use default
                    inherit = origin or getfenv( 0 )
                end
                -- Now that we have an inherit table, inherit from it
                space = table_clone( inherit )
                local inherit_mt = getmetatable( inherit )
                if inherit_mt then
                    local space_mt = table_clone( inherit_mt )
                    local inherit_mt_mt = getmetatable( inherit_mt )
                    if inherit_mt_mt then setmetatable( space_mt, inherit_mt_mt ) end
                    setmetatable( space, space_mt )
                end
                -- Set up space
                space.namespace = namespace_return
                space.current_namespace = name
                if name then namespace.spaces[name] = space end
                if preload_construct then preload_construct( space ) end -- Must do after "spaces" populated
            end
            return space
        end

        -- Set the globals of the calling file to the namespace named "name".
        -- As with space(), "name" can be nil and "inherit" can be a default.
        -- Can be called with "namespace()"
        local function enter( _, name, inherit )
            setfenv( 2, namespace.space( name, inherit ) )
        end
        namespace_mt.__call = enter

        -- Fancy features

        -- Create a lazy-load namespace.
        -- On first attempt to load namespace 'inherit' will be inherited,
        -- and 'construct' will be called with the new space table as argument.
        function namespace.prepare( name, inherit, construct )
            if preload[name] then
                error( string.format( 'Called prepare() twice on namespace "%s"', name ) )
            end
            if namespace.spaces[name] then
                error( string.format( 'Called prepare() on already-existing namespace "%s"', name ) )
            end
            preload[name] = {inherit, construct}
        end

        -- Call this before calling require() or unpollute().
        -- This freezes a "clean" globals table as the default table to inherit from when creating a namespace.
        -- Pass no argument to use the "default environment" (the globals table registered to use for new requires)
        -- Pass a table to set that table as the origin.
        -- Pass a "namespace" argument to use that namespace as the origin.
        function namespace.origin( t, inherit )
            origin = nil
            origin = type( t ) == 'table' and t or namespace.space( t, inherit )
        end

        -- If you believe a require has been leaving junk in the global namespace,
        -- this will reset the "default environment" (the globals table registered to use for new requires)
        -- to the origin. (The globals of the file calling unpollute() will be unaffected.)
        -- Pass a "namespace" argument to use that namespace instead of a clean table. 
        function namespace.unpollute( name, inherit )
            if not (origin or name or inherit) then
                error( 'Called unpollute() without setting an origin first' )
            end
            setfenv( 0, namespace.space( name, inherit ) )
        end

        -- This will perform a require, with the given namespace preset for globals.
        -- If no name is given, it will make a new clean namespace (preventing it from polluting any globals table)
        function namespace.require( torequire, name, inherit )
            local old_zero = getfenv( 0 )
            setfenv( 0, namespace.space( name, inherit ) )
            local result = require( torequire )
            setfenv( 0, old_zero )
            return result
        end

        -- Store stuff in here that you want to pass between namespaces
        namespace.globals = {}

        return namespace_return
    end
end

do
    local _ENV = _ENV
    package.preload['configReader'] = function( ... )
        local arg = _G.arg;
        --- Reads configuration files into a Lua table.
        --  Understands INI files, classic Unix config files, and simple
        -- delimited columns of values. See @{06-data.md.Reading_Configuration_Files|the Guide}
        --
        --    # test.config
        --    # Read timeout in seconds
        --    read.timeout=10
        --    # Write timeout in seconds
        --    write.timeout=5
        --    #acceptable ports
        --    ports = 1002,1003,1004
        --
        --    -- readconfig.lua
        --    local config = require 'config'
        --    local t = config.read 'test.config'
        --    print(pretty.write(t))
        --
        --    ### output #####
        --    {
        --      ports = {
        --        1002,
        --        1003,
        --        1004
        --      },
        --      write_timeout = 5,
        --      read_timeout = 10
        --    }
        --
        -- @module configReader
        local type, tonumber, ipairs, io, table = _G.type, _G.tonumber, _G.ipairs, _G.io, _G.table

        local function split( s, re )
            local res = {}
            local t_insert = table.insert
            re = '[^' .. re .. ']+'
            for k in s:gmatch( re ) do t_insert( res, k ) end
            return res
        end

        local function strip( s ) return s:gsub( '^%s+', '' ):gsub( '%s+$', '' ) end

        local function strip_quotes( s ) return s:gsub( '[\'"](.*)[\'"]', '%1' ) end

        ---@class configReader
        local configReader = {}

        --- like io.lines(), but allows for lines to be continued with '\'.
        -- @param file file* file-like object (anything where read() returns the next line) or a filename.
        -- Defaults to stardard input.
        -- @return function an iterator over the lines, or nil
        -- @return string 'not a file-like object' or 'file is nil'
        function configReader.lines( file )
            local f, openf, err
            local line = ''
            if type( file ) == 'string' then
                f, err = io.open( file, 'r' )
                if not f then return nil, err end
                openf = true
            else
                f = file or io.stdin
                if not file.read then return nil, 'not a file-like object' end
            end
            if not f then return nil, 'file is nil' end
            return function()
                local l = f:read()
                while l do
                    -- only for non-blank lines that don't begin with either ';' or '#'
                    if l:match '%S' and not l:match '^%s*[;#]' then
                        -- does the line end with '\'?
                        local i = l:find '\\%s*$'
                        if i then -- if so,
                            line = line .. l:sub( 1, i - 1 )
                        elseif line == '' then
                            return l
                        else
                            l = line .. l
                            line = ''
                            return l
                        end
                    end
                    l = f:read()
                end
                if openf then f:close() end
            end
        end

        --- read a configuration file into a table
        -- @param file either a file-like object or a string, which must be a filename
        -- @tab[opt] cnfg a configuration table that may contain these fields:
        --
        --  * `smart`  try to deduce what kind of config file we have (default false)
        --  * `variablilize` make names into valid Lua identifiers (default true)
        --  * `convert_numbers` try to convert values into numbers (default true)
        --  * `trim_space` ensure that there is no starting or trailing whitespace with values (default true)
        --  * `trim_quotes` remove quotes from strings (default false)
        --  * `list_delim` delimiter to use when separating columns (default ',')
        --  * `keysep` separator between key and value pairs (default '=')
        --
        -- @return a table containing items, or `nil`
        -- @return error message (same as @{config.lines}
        function configReader.read( file, cnfg )
            local f, openf, err, auto

            local iter, err = configReader.lines( file )
            if not iter then return nil, err end
            local line = iter()
            cnfg = cnfg or {}
            if cnfg.smart then
                auto = true
                if line:match '^[^=]+=' then
                    cnfg.keysep = '='
                elseif line:match '^[^:]+:' then
                    cnfg.keysep = ':'
                    cnfg.list_delim = ':'
                elseif line:match '^%S+%s+' then
                    cnfg.keysep = ' '
                    -- more than two columns assume that it's a space-delimited list
                    -- cf /etc/fstab with /etc/ssh/ssh_config
                    if line:match '^%S+%s+%S+%s+%S+' then cnfg.list_delim = ' ' end
                    cnfg.variabilize = false
                end
            end

            local function check_cnfg( var, def )
                local val = cnfg[var]
                if val == nil then
                    return def
                else
                    return val
                end
            end

            local initial_digits = '^[%d%+%-]'
            local t = {}
            local top_t = t
            local variablilize = check_cnfg( 'variabilize', true )
            local list_delim = check_cnfg( 'list_delim', ',' )
            local convert_numbers = check_cnfg( 'convert_numbers', true )
            local trim_space = check_cnfg( 'trim_space', true )
            local trim_quotes = check_cnfg( 'trim_quotes', false )
            local ignore_assign = check_cnfg( 'ignore_assign', false )
            local keysep = check_cnfg( 'keysep', '=' )
            local keypat = keysep == ' ' and '%s+' or '%s*' .. keysep .. '%s*'
            if list_delim == ' ' then list_delim = '%s+' end

            local function process_name( key )
                if variablilize then key = key:gsub( '[^%w]', '_' ) end
                return key
            end

            local function process_value( value )
                if list_delim and value:find( list_delim ) then
                    value = split( value, list_delim )
                    for i, v in ipairs( value ) do value[i] = process_value( v ) end
                elseif convert_numbers and value:find( initial_digits ) then
                    local val = tonumber( value )
                    if not val and value:match ' kB$' then
                        value = value:gsub( ' kB', '' )
                        val = tonumber( value )
                    end
                    if val then value = val end
                end
                if type( value ) == 'string' then
                    if trim_space then value = strip( value ) end
                    if not trim_quotes and auto and value:match '^"' then
                        trim_quotes = true
                    end
                    if trim_quotes then value = strip_quotes( value ) end
                end
                return value
            end

            while line do
                if line:find( '^%[' ) then -- section!
                    local section = process_name( line:match( '%[([^%]]+)%]' ) )
                    t = top_t
                    t[section] = {}
                    t = t[section]
                else
                    line = line:gsub( '^%s*', '' )
                    local i1, i2 = line:find( keypat )
                    if i1 and not ignore_assign then -- key,value assignment
                        local key = process_name( line:sub( 1, i1 - 1 ) )
                        local value = process_value( line:sub( i2 + 1 ) )
                        t[key] = value
                    else -- a plain list of values...
                        t[#t + 1] = process_value( line )
                    end
                end
                line = iter()
            end
            return top_t
        end

        return configReader
    end
end
