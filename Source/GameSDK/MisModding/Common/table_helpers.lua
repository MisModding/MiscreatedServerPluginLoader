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
--
--

local table = table

--- Get the value from the table based on a string path to the property
--- like `'MyProperty.MySubProperty.key'`
---@param tbl table         the table to get the value from
---@param path string       the path to the property
---@return string|number|boolean|table|nil
function table.GetPath( tbl, path )
    if not path then return nil, 'no path provided' end
    local pathParts = string.split( path, '%.' )
    for i, part in ipairs( pathParts ) do
        if tbl[part] then
            tbl = tbl[part]
        else
            return nil, 'property not found'
        end
    end
    return tbl
end

--- Set the value from the table based on a string path to the property
--- like `'MyProperty.MySubProperty.key'`
---@param tbl table         table to set the value on
---@param path string       path to the property
---@param value string|number|boolean|table
---@return boolean
function table.SetPath( tbl, path, value )
    if not path then return false, 'no path provided' end
    local pathParts = string.split( path, '%.' )
    for i, part in ipairs( pathParts ) do
        if i == #pathParts then
            tbl[part] = value
        elseif tbl[part] then
            tbl = tbl[part]
        else
            return false, 'property not found'
        end
    end
    return true
end

RegisterModule('MisModding.Common.tableHelpers', table)
return table