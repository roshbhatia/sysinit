local agents_config = require("sysinit.config.agents_config").load_config()
local M = {}

M.plugins = {
  {
    enabled = agents_config.agents.enabled and agents_config.agents.copilot.enabled,
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      "zbirenbaum/copilot.lua",
      "nvim-lua/plenary.nvim",
    },
    build = "make tiktoken",
    cmd = {
      "CopilotChat",
      "CopilotChatOpen",
      "CopilotChatToggle",
      "CopilotChatExplain",
      "CopilotChatTests",
      "CopilotChatFix",
      "CopilotChatOptimize",
      "CopilotChatDocs",
    },
    opts = {
      window = {
        layout = "horizontal",
        border = "rounded",
        relative = "editor",
      },
    },
  },
}
return M
