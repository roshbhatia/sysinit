-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/CopilotC-Nvim/CopilotChat.nvim/master/doc/CopilotChat.txt"
local M = {}

M.plugins = {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    lazy = true,
    cmd = {
      "CopilotChat",
      "CopilotChatOpen",
      "CopilotChatToggle",
      "CopilotChatClose",
      "CopilotChatReset",
      "CopilotChatExplain",
      "CopilotChatReview",
      "CopilotChatFix",
      "CopilotChatOptimize",
      "CopilotChatDocs",
      "CopilotChatTests",
      "CopilotChatCommit",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "github/copilot.vim",
    },
    config = function()
      local chat = require("CopilotChat")
      local wk = require("which-key")
      
      chat.setup({
        -- Model and agent configuration
        model = "gpt-4o",  -- Using the latest model for better results
        agent = "none",    -- Default agent
        
        -- User interface configuration
        window = {
          layout = "float",
          width = 0.8,
          height = 0.7,
          border = "rounded",
          title = "Copilot Chat",
        },
        
        -- Context and selection settings
        highlight_selection = true,
        auto_follow_cursor = true,
        auto_insert_mode = true,
        
        -- Input/output behavior
        show_help = true,
        clear_chat_on_new_prompt = false,
        
        -- Custom or extended prompts
        prompts = {
          ImplementFeature = {
            prompt = "Implement a new feature based on the context and description below.",
            context = "buffer",
          },
          DebugThis = {
            prompt = "Debug the selected code and provide a detailed explanation of the problem and solution.",
            context = "buffer",
          },
          ExplainInSimple = {
            prompt = "Explain the selected code in simple terms as if teaching to a beginner.",
            context = "buffer",
          },
        },
      })
    end
  }
}

return M