-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/kdheepak/lazygit.nvim/refs/heads/main/README.md"
local M = {}

M.plugins = {{
    "kdheepak/lazygit.nvim",
    event = "VeryLazy",
    dependencies = {"nvim-lua/plenary.nvim", "lewis6991/gitsigns.nvim", "tpope/vim-fugitive"},
    config = function()
        require("gitsigns").setup()
        vim.g.lazygit_floating_window_winblend = 0
        vim.g.lazygit_floating_window_scaling_factor = 0.9
        vim.g.lazygit_floating_window_border_chars = {'╭', '─', '╮', '│', '╯', '─', '╰', '│'}
        vim.g.lazygit_floating_window_use_plenary = 0
        vim.g.lazygit_use_neovim_remote = vim.v.headless and 0 or 1
        pcall(function()
            require("telescope").load_extension("lazygit")
        end)
    end
}}

return M
