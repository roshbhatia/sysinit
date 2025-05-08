local M = {}

M.plugins = {{
    "GeorgesAlkhouri/nvim-aider",
    lazy = false,
    dependencies = {"folke/snacks.nvim"},
    keys = {{
        "<leader>a/",
        "<cmd>Aider toggle<cr>",
        desc = "AI: Toggle Chat"
    }, {
        "<leader>as",
        "<cmd>Aider send<cr>",
        desc = "AI: Send to Chat",
        mode = {"n", "v"}
    }, {
        "<leader>ac",
        "<cmd>Aider command<cr>",
        desc = "AI: Chat Commands"
    }, {
        "<leader>ab",
        "<cmd>Aider buffer<cr>",
        desc = "AI: Send Buffer"
    }, {
        "<leader>a+",
        "<cmd>Aider add<cr>",
        desc = "AI: Add File"
    }, {
        "<leader>a-",
        "<cmd>Aider drop<cr>",
        desc = "AI: Drop File"
    }, {
        "<leader>ar",
        "<cmd>Aider add readonly<cr>",
        desc = "AI: Add Read-Only"
    }, {
        "<leader>aR",
        "<cmd>Aider reset<cr>",
        desc = "AI: Reset Session"
    }},
    config = function()
        require("nvim_aider").setup({
            picker_cfg = {
                preset = "telescope"
            }
        })
    end
}}

return M
