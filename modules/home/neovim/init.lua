--[[
Neovim Configuration
====================
This configuration aims to provide a VSCode-like experience with Neovim's power.
]]--

-- Set up Lua paths for this configuration
do
  local config_path = vim.fn.expand('<sfile>:p:h')
  package.path = config_path .. '/lua/?.lua;' .. 
                 config_path .. '/lua/?/init.lua;' .. 
                 package.path
end

-- Initialize Neovim configuration

-- Load core components
require("core.options")  -- Basic Vim options
require("core.keymaps")  -- Key mappings
require("core.autocmds") -- Auto commands

-- Initialize lazy.nvim and load plugins
require("config.config").setup()