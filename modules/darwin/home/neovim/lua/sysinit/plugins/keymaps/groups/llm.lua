-- llm.lua
-- LLM/AI assistant keybindings
local M = {}

-- Reference to the main keymaps module
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    -- Register LLM group with the main keymaps module
    keymaps.register_group("i", keymaps.group_icons.llm .. " LLM", {
        {
            key = "t",
            desc = "Toggle Chat",
            neovim_cmd = "<cmd>AvanteToggle<CR>",
            vscode_cmd = "workbench.action.chat.toggle"
        },
        {
            key = "n",
            desc = "New Chat",
            neovim_cmd = "<cmd>CopilotChatOpen<CR>",
            vscode_cmd = "workbench.action.chat.newChat"
        },
        {
            key = "s",
            desc = "Stop Chat",
            neovim_cmd = "<cmd>CopilotChatStop<CR>",
            vscode_cmd = "workbench.action.chat.stopListening"
        },
        {
            key = "r",
            desc = "Reset Chat",
            neovim_cmd = "<cmd>CopilotChatReset<CR>",
            vscode_cmd = "workbench.action.chat.clearHistory"
        },
        {
            key = "e",
            desc = "Explain Code",
            neovim_cmd = "<cmd>CopilotChatExplain<CR>",
            vscode_cmd = "github.copilot.chat.explain"
        },
        {
            key = "f",
            desc = "Fix Code",
            neovim_cmd = "<cmd>CopilotChatFix<CR>",
            vscode_cmd = "github.copilot.chat.fix"
        },
        {
            key = "d",
            desc = "Generate Docs",
            neovim_cmd = "<cmd>CopilotChatDocs<CR>",
            vscode_cmd = "github.copilot.chat.generateDocs"
        },
        {
            key = "g",
            desc = "Generate Tests",
            neovim_cmd = "<cmd>CopilotChatTests<CR>",
            vscode_cmd = "github.copilot.chat.generateTests"
        }
    })
end

-- Add any LLM-specific plugins here
M.plugins = {}

return M