local M = {}

M.plugins = {{
    "folke/trouble.nvim",
    lazy = false,
    dependencies = {"nvim-tree/nvim-web-devicons", "nvim-telescope/telescope.nvim"},
    config = function()
        require("trouble").setup()

        local actions = require("telescope.actions")
        local open_with_trouble = require("trouble.sources.telescope").open

        -- Use this to add more results without clearing the trouble list
        local add_to_trouble = require("trouble.sources.telescope").add

        local telescope = require("telescope")

        telescope.setup({
            defaults = {
                mappings = {
                    i = {
                        ["<c-t>"] = open_with_trouble
                    },
                    n = {
                        ["<c-t>"] = open_with_trouble
                    }
                }
            }
        })
    end,
    keys = function()
        return {{
            "<leader>xx",
            "<cmd>Trouble diagnostics toggle<cr>",
            desc = "Problems: Diagnostics"
        }, {
            "<leader>xX",
            "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
            desc = "Problems: Buffer Diagnostics"
        }, {
            "<leader>cs",
            "<cmd>Trouble symbols toggle focus=false<cr>",
            desc = "Problems: Symbols"
        }, {
            "<leader>cl",
            "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
            desc = "Problems: LSP Definitions / references / ..."
        }, {
            "<leader>xL",
            "<cmd>Trouble loclist toggle<cr>",
            desc = "Problems: Location List"
        }, {
            "<leader>xQ",
            "<cmd>Trouble qflist toggle<cr>",
            desc = "Problems: Quickfix List"
        }}
    end
}}

return M
