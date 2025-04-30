-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/kdheepak/lazygit.nvim/refs/heads/main/README.md"
-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/lewis6991/gitsigns.nvim/refs/heads/main/doc/gitsigns.txt"
-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/tpope/vim-fugitive/refs/heads/master/doc/fugitive.txt"
local M = {}

M.plugins = {{
    "kdheepak/lazygit.nvim",
    commit = "b9eae3badab982e71abab96d3ee1d258f0c07961",
    event = "VeryLazy",
    dependencies = {"nvim-lua/plenary.nvim", "lewis6991/gitsigns.nvim", "tpope/vim-fugitive",
                    "nvim-telescope/telescope.nvim"},
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
