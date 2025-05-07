local M = {}

M.plugins = {{
    "pwntester/octo.nvim",
    lazy = false,
    dependencies = {"nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim"},
    keys = function()
        return {{
            "<leader>gh",
            "<cmd>Octo<CR>",
            desc = "GitHub: open client"
        }, {
            "<leader>gH",
            "<cmd>Octo pr list<CR>",
            desc = "GitHub: open PR list"
        }, {
            "<leader>gP",
            "<cmd>Octo pr create<CR>",
            desc = "GitHub: create PR"
        }, {
            "<leader>gC",
            "<cmd>Octo issue create<CR>",
            desc = "GitHub: create issue"
        }}
    end
}}

return M
