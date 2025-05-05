local M = {}

M.plugins = {{
    "CopilotC-Nvim/CopilotChat.nvim",
    lazy = false,
    dependencies = {"zbirenbaum/copilot.lua", {
        "nvim-lua/plenary.nvim",
        branch = "master"
    }},
    build = "make tiktoken",
    opts = {
        window = {
            layout = 'float', -- 'vertical', 'horizontal', 'float', 'replace', or a function that returns the layout
            width = 0.5, -- width of the window
            height = 0.5, -- height of the window
            border = "rounded", -- border style
            relative = "editor", -- 'editor', 'cursor', or 'win'
            title = "Copilot Chat" -- title of the window
        }
    }
}}

return M
