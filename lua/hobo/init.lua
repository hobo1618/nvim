-- Add these lines to your Neovim configuration
local package_path = '/home/hobo/.luarocks/share/lua/5.1/?.lua;;'
local package_cpath = '/home/hobo/.luarocks/lib/lua/5.1/?.so;;'

package.path = package.path .. package_path
package.cpath = package.cpath .. package_cpath

require("hobo.set");
require("hobo.remap");
require("hobo.commands");
