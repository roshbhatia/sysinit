local options = require('sysinit.pkg.options')
local plugin_manager = require('sysinit.pkg.plugin_manager')

local config_path = vim.fn.stdpath('config')
package.path = package.path .. ";" .. config_path .. "/?.lua" .. ";" .. config_path .. "/lua/?.lua"

local editor_host
if vim.g.vscode then
    editor_host = require("sysinit.entrypoints.vscode")
else
    editor_host = require("sysinit.entrypoints.neovim")
end

options.setup_shared()
editor_host.setup_options()
editor_host.setup_actions()

plugin_manager.setup_package_manager()
local plugins = editor_host.get_plugins()
plugin_manager.setup_plugins(plugins)
