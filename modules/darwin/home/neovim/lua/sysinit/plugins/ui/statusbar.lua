-- statusbar.lua
-- Statusbar configuration for both Neovim and VSCode
local M = {}

-- Neovim-only statusbar plugin (Staline)
local staline_plugin = {
    "tamton-aquib/staline.nvim",
    event = "VeryLazy", -- Load after UI is ready
    enabled = function()
        return not vim.g.vscode
    end,
    opts = {
        sections = {
            left = {"mode", "branch", "file_name"},
            mid = {"lsp"},
            right = {"line_column"}
        }
    }
}

-- Plugin setup for lazy.nvim
M.plugins = {staline_plugin}

return M