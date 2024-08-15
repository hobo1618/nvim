-- Add LuaRocks paths
local home = os.getenv("HOME")
local luarocks_path = home .. '/.luarocks'

local package_path_str = table.concat({
    '~/' .. luarocks_path .. '/share/lua/5.1/?.lua',
    luarocks_path .. '/share/lua/5.1/?/init.lua',
    luarocks_path .. '/share/lua/5.3/?.lua',
    luarocks_path .. '/share/lua/5.3/?/init.lua',
    luarocks_path .. '/share/lua/5.4/?.lua',
    luarocks_path .. '/share/lua/5.4/?/init.lua',
    package.path
}, ";")

local install_cpath_pattern = table.concat({
    luarocks_path .. '/lib/lua/5.1/?.so',
    luarocks_path .. '/lib/lua/5.3/?.so',
    luarocks_path .. '/lib/lua/5.4/?.so',
    package.cpath
}, ";")

if not string.find(package.path, package_path_str, 1, true) then
    package.path = package.path .. ';' .. package_path_str
end

if not string.find(package.cpath, install_cpath_pattern, 1, true) then
    package.cpath = package.cpath .. ';' .. install_cpath_pattern
end

package.path = package.path .. ';/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua'
package.cpath = package.cpath .. ';/usr/local/lib/lua/5.1/?.so'

-- -- Use a Lua module installed via LuaRocks
-- local pl = require('pl.pretty')
-- pl.dump({key = 'value'})
--
-- local http = require('http.client')

