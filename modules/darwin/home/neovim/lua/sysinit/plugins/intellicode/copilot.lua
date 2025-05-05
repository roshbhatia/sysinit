local M = {}

M.plugins = {{
    "zbirenbaum/copilot.lua",
    lazy = false,
    config = function()
        require("copilot").setup({
            suggestion = {
                enabled = false
            },
            panel = {
                enabled = false
            },
            copilot_model = "gpt-4o-copilot"
        })
    end
}}

return M
