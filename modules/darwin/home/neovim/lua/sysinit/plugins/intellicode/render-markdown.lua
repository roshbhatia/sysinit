local M = {}

M.plugins = {{
    "MeanderingProgrammer/render-markdown.nvim",
    lazy = false,
    opts = {
        file_types = {"markdown", "Avante"}
    }
}}

return M
