local options = require('sysinit.pkg.options')
local plugin_manager = require('sysinit.pkg.plugin_manager')

local config_path = vim.fn.stdpath('config')
package.path = package.path .. ";" .. config_path .. "/?.lua" .. ";" .. config_path .. "/lua/?.lua"

local editor_host = vim.g.vscode
require("sysinit.entrypoints.vscode"):require("sysinit.entrypoints.neovim")

options.setup_shared()
editor_host.setup_options()
editor_host.setup_actions()
local plugins = editor_host.get_plugins()
local specs = plugin_manager.collect_plugin_specs(plugins)
plugin_manager.setup_package_manager(specs)
plugin_manager.run_plugin_post_setup(plugins)
