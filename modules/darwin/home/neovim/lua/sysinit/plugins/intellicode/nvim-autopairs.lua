local M = {}

M.plugins = {{
    "windwp/nvim-autopairs",
    lazy = true,
    event = "InsertEnter",
    config = true
}}

return M
