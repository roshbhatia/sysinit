local M = {}

M.plugins = {{
    "olimorris/codecompanion.nvim",
    opts = {},
    dependencies = {"nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter"},
    keys = function()
        return {{
            "<leader>ae",
            "<cmd>CopilotChatExplain<cr>",
            desc = "AI: Toggle Chat"
        }, {
            "<leader>ae",
            "<cmd>CopilotChatExplain<cr>",
            desc = "AI: Explain Code"
        }, {
            "<leader>at",
            "<cmd>CopilotChatTests<cr>",
            desc = "AI: Generate Tests"
        }, {
            "<leader>af",
            "<cmd>CopilotChatFix<cr>",
            desc = "AI: Fix Code"
        }, {
            "<leader>ao",
            "<cmd>CopilotChatOptimize<cr>",
            desc = "AI: Optimize Code"
        }, {
            "<leader>ad",
            "<cmd>CopilotChatDocs<cr>",
            desc = "AI: Generate Docs"
        }}
    end,
    config = function()
        require("codecompanion").setup()
    end
}}

return M
