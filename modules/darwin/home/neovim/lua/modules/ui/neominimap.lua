-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/Isrothy/neominimap.nvim/refs/heads/main/doc/neominimap.nvim.txt"
local M = {}

M.plugins = {{
    "Isrothy/neominimap.nvim",
    version = "v3.x.x",
    event = "BufReadPost",
    config = function()
        vim.opt.wrap = false
        vim.opt.sidescrolloff = 36

        vim.g.neominimap = {
            auto_enable = false
        }
    end
}}

return M
