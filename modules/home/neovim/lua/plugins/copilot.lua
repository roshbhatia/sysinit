-- GitHub Copilot plugin configuration
return {
  -- GitHub Copilot
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 75,
          keymap = {
          accept = "<C-y>",
          accept_word = "<C-w>",
          accept_line = "<C-l>",
          next = "<C-n>",
          prev = "<C-p>",
          dismiss = "<C-]>",
          },
        },
        panel = {
          enabled = true,
          auto_refresh = true,
          keymap = {
            jump_prev = "<C-p>",
            jump_next = "<C-n>",
            accept = "<CR>",
            refresh = "r",
            open = "<C-CR>",
          },
          layout = {
            position = "bottom",
            ratio = 0.4,
          },
        },
        filetypes = {
          yaml = true,
          markdown = true,
          help = false,
          gitcommit = true,
          gitrebase = false,
          hgcommit = false,
          svn = false,
          cvs = false,
          ["."] = false,
        },
      })
    end,
  },
  
  -- GitHub Copilot Chat integration
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    opts = {
      debug = false,
      show_help = true,
      prompts = {
        Explain = {
          prompt = "Explain how this code works.",
        },
        Tests = {
          prompt = "Generate unit tests for this code.",
        },
        Fix = {
          prompt = "Fix the issues in this code.",
        },
        Optimize = {
          prompt = "Optimize this code to make it more efficient.",
        },
        Docs = {
          prompt = "Write documentation for this code.",
        },
      },
    },
    keys = {
      { "<leader>cc", ":CopilotChat<CR>", desc = "CopilotChat - Open" },
      { "<leader>ce", ":CopilotChatExplain<CR>", desc = "CopilotChat - Explain code" },
      { "<leader>ct", ":CopilotChatTests<CR>", desc = "CopilotChat - Generate tests" },
      { "<leader>cf", ":CopilotChatFix<CR>", desc = "CopilotChat - Fix issues" },
      { "<leader>co", ":CopilotChatOptimize<CR>", desc = "CopilotChat - Optimize code" },
      { "<leader>cd", ":CopilotChatDocs<CR>", desc = "CopilotChat - Write docs" },
    },
  },
}
