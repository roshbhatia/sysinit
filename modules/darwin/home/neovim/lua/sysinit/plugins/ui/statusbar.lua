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
    config = function()
        require("staline").setup({
            sections = {
                left = {"mode", "branch", "file_name"},
                mid = {"lsp"},
                right = {"line_column"}
            },
            mode_colors = {
                n = "#7aa2f7",    -- Normal
                i = "#9ece6a",    -- Insert
                c = "#7dcfff",    -- Command
                v = "#bb9af7",    -- Visual
                V = "#bb9af7",    -- Visual Line
                [""] = "#bb9af7", -- Visual Block
                R = "#f7768e",    -- Replace
                s = "#ff9e64",    -- Select
                S = "#ff9e64",    -- Select Line
                [""] = "#ff9e64", -- Select Block
                t = "#73daca",    -- Terminal
            },
            defaults = {
                true_colors = true,
                line_column = " [%l/%L] :%c ",
                branch_symbol = " ",
                mod_symbol = "  ",
            },
            special_table = {
                NvimTree = { 'File Explorer', ' ' },
                packer = { 'Packer', ' ' },
                alpha = { 'Dashboard', ' ' }, -- Hide on alpha screen
            },
        })
        
        -- Ensure the statusline is always visible (except in specific buffers)
        vim.api.nvim_create_augroup("staline_setup", { clear = true })
        vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
            group = "staline_setup",
            callback = function()
                local ft = vim.bo.filetype
                if ft ~= "alpha" then
                    vim.opt.laststatus = 3  -- Global statusline
                end
            end
        })
        
        -- Hide statusline in alpha
        vim.api.nvim_create_autocmd({"FileType"}, {
            pattern = "alpha",
            group = "staline_setup",
            callback = function()
                vim.opt.laststatus = 0  -- Hide statusline
            end
        })
    end
}

-- Plugin setup for lazy.nvim
M.plugins = {staline_plugin}

return M