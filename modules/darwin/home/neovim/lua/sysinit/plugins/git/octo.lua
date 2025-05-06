local M = {}

M.plugins = {{
    "pwntester/octo.nvim",
    lazy = false,
    event = "VeryLazy",
    opts = {
        mappings_disable_default = true,
        suppress_missing_scope = {
            projects_v2 = true
        }
    }
}}

return M
