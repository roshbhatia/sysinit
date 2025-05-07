local M = {}

M.plugins = {
    {
        "kdheepak/lazygit.nvim",
        cmd = "LazyGit",
        keys = {
            { "<leader>gg", "<cmd>LazyGit<CR>", desc = "Open LazyGit" },
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = function()
            -- LazyGit configuration
            vim.g.lazygit_floating_window_winblend = 0
            vim.g.lazygit_floating_window_scaling_factor = 0.9
            vim.g.lazygit_floating_window_corner_chars = {'╭', '╮', '╰', '╯'}
            vim.g.lazygit_floating_window_use_plenary = 1
            vim.g.lazygit_use_neovim_remote = 0
        end
    }
}

return M