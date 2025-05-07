-- Example init.lua showing how to use the AI assistance integration module

-- First, we need to require the module_loader
local module_loader = require("module_loader")

-- Define our modules
local modules = {
    require("copilot_module"),
    require("copilot_keymap"),
    -- Add other modules here as needed
}

-- Get plugin specifications for lazy.nvim or other plugin managers
local plugin_specs = module_loader.get_plugin_specs(modules)

-- Example of setting up with lazy.nvim
-- This is just an example - in your real config, you'd use the actual lazy.nvim API
if pcall(require, "lazy") then
    require("lazy").setup(plugin_specs)
end

-- Setup all modules (this will run the setup function in modules that have one)
module_loader.setup_modules(modules)

-- Set autoread to true for auto reloading buffers changed by Aider
vim.opt.autoread = true

-- Add any global vim options needed
vim.opt.updatetime = 100 -- Faster update time for better responsiveness
vim.opt.termguicolors = true -- Enable true color support

-- Optional: Add any autocommands or additional settings
vim.api.nvim_create_autocmd("FileType", {
    pattern = {"gitcommit", "markdown"},
    callback = function()
        -- Disable Copilot for specific filetypes
        vim.b.copilot_enabled = false
    end,
})

-- Add auto-command to check for external file changes more frequently
vim.api.nvim_create_autocmd({"FocusGained", "BufEnter", "CursorHold", "CursorHoldI"}, {
    pattern = "*",
    callback = function()
        if vim.fn.mode() ~= "c" then
            vim.cmd("checktime")
        end
    end,
})

-- Add command to open Aider quickly
vim.api.nvim_create_user_command("AI", "Aider toggle", {})

-- Set Aider as a global helper
_G.aider = require("nvim_aider").api

-- Create a command for theme switching using NvChad
vim.api.nvim_create_user_command("Theme", function()
    local present, themes = pcall(require, "telescope.builtin")
    if present then
        themes.colorscheme()
    else
        vim.notify("Telescope not available for theme switching", vim.log.levels.WARN)
    end
end, {})

-- Example of setting up with lazy.nvim
-- This is just an example - in your real config, you'd use the actual lazy.nvim API
if pcall(require, "lazy") then
    require("lazy").setup(plugin_specs)
end

-- Setup all modules (this will run the setup function in modules that have one)
module_loader.setup_modules(modules)

-- Set autoread to true for auto reloading buffers changed by Aider
vim.opt.autoread = true

-- Add any global vim options needed
vim.opt.updatetime = 100 -- Faster update time for better responsiveness

-- Optional: Add any autocommands or additional settings
vim.api.nvim_create_autocmd("FileType", {
    pattern = {"gitcommit", "markdown"},
    callback = function()
        -- Disable Copilot for specific filetypes
        vim.b.copilot_enabled = false
    end,
})

-- Add auto-command to check for external file changes more frequently
vim.api.nvim_create_autocmd({"FocusGained", "BufEnter", "CursorHold", "CursorHoldI"}, {
    pattern = "*",
    callback = function()
        if vim.fn.mode() ~= "c" then
            vim.cmd("checktime")
        end
    end,
})

-- Add command to open Aider quickly
vim.api.nvim_create_user_command("AI", "Aider toggle", {})

-- Set Aider as a global helper
_G.aider = require("nvim_aider").api
