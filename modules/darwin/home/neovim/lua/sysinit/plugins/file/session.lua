-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/rmagatti/auto-session/refs/heads/main/doc/auto-session.txt"
local M = {}

M.plugins = {{
    "folke/persistence.nvim",
    lazy = false,
    priority = 100,
    opts = {}
}}

return M

