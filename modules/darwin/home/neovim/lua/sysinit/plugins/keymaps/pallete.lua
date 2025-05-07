-- pallete.lua
-- A simple wrapper module that loads the new keymap system
local M = {}

-- Import the new keymaps module
local keymaps = require("sysinit.plugins.keymaps")

-- Define plugins using the plugins from the keymaps module
M.plugins = keymaps.plugins

-- For backward compatibility, expose any needed functions or tables
M.group_icons = keymaps.group_icons
M.keybindings_data = keymaps.keybindings_data

return M