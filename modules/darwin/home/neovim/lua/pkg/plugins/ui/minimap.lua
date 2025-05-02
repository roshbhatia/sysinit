-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/Isrothy/neominimap.nvim/refs/heads/main/doc/neominimap.nvim.txt"
local M = {}

M.plugins = {{
    "Isrothy/neominimap.nvim",
    event = "BufReadPost",
    lazy = false,
    init = function()
        vim.opt_local.wrap = false
        vim.opt_local.sidescrolloff = 36

        vim.g.neominimap = {
            auto_enable = false
        }
    end
}}

return M
