local M = {}

M.plugins = {{
    "zbirenbaum/copilot-cmp",
    lazy = true,
    event = "InsertEnter",
    dependencies = {"zbirenbaum/copilot.lua"},
    config = function()
        require("copilot_cmp").setup()
    end
}}

return M
