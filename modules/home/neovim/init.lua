--[[
Sysinit.nvim: A modular Neovim configuration
Author: Roshan Bhatia (@roshbhatia)
License: MIT
--]]

-- Load bootstrap script and initialize
require("bootstrap").bootstrap()

-- That's it! The bootstrap script takes care of the rest
-- The module system is loaded in the following order:
-- 1. core module is loaded first
-- 2. module dependencies are resolved
-- 3. modules are loaded in dependency order
-- 4. plugins are configured and loaded

-- Set vim.g.neovide if running in Neovide
if vim.g.neovide then
  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_cursor_trail_length = 0.3
  vim.g.neovide_cursor_antialiasing = true
  vim.g.neovide_cursor_vfx_mode = "ripple"
  vim.g.neovide_remember_window_size = true
  vim.g.neovide_floating_blur_amount_x = 2.0
  vim.g.neovide_floating_blur_amount_y = 2.0
end
