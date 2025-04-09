-- Advanced Copilot integration with high-quality prompts
return {
  -- Copilot.vim for basic completion
  {
    "github/copilot.vim",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
      vim.g.copilot_tab_fallback = ""
      
      -- Make copilot suggest using Ctrl+y
      vim.keymap.set("i", "<C-y>", 'copilot#Accept("<CR>")', {
        expr = true,
        replace_keycodes = false,
        silent = true,
      })
      
      -- Show copilot suggestions using Ctrl+h
      vim.keymap.set("i", "<C-h>", "<cmd>Copilot panel<CR>", { silent = true })
      
      -- Navigate through suggestions
      vim.keymap.set("i", "<C-n>", "<Plug>(copilot-next)", { silent = true })
      vim.keymap.set("i", "<C-p>", "<Plug>(copilot-previous)", { silent = true })
      
      -- Toggle copilot
      vim.keymap.set("n", "<leader>ct", "<cmd>Copilot toggle<CR>", { desc = "Toggle Copilot" })
    end,
  },
  
  -- Enhanced Copilot Chat with advanced prompts
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary",
    dependencies = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim" },
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    cmd = {
      "CopilotChat",
      "CopilotChatOpen",
      "CopilotChatClose",
      "CopilotChatToggle",
      "CopilotChatReset",
      "CopilotChatSave",
      "CopilotChatLoad",
      "CopilotChatTests",
      "CopilotChatExplain",
      "CopilotChatFix",
      "CopilotChatOptimize",
      "CopilotChatDocs",
      "CopilotChatCommit",
      "CopilotChatRefactor",
    },
    keys = {
      { "<leader>cc", "<cmd>CopilotChat<CR>", desc = "CopilotChat - Open" },
      { "<leader>ce", "<cmd>CopilotChatExplain<CR>", desc = "CopilotChat - Explain code" },
      { "<leader>cf", "<cmd>CopilotChatFix<CR>", desc = "CopilotChat - Fix issues" },
      { "<leader>co", "<cmd>CopilotChatOptimize<CR>", desc = "CopilotChat - Optimize code" },
      { "<leader>cd", "<cmd>CopilotChatDocs<CR>", desc = "CopilotChat - Write docs" },
      { "<leader>ct", "<cmd>CopilotChatTests<CR>", desc = "CopilotChat - Generate tests" },
      { "<leader>cg", "<cmd>CopilotChatCommit<CR>", desc = "CopilotChat - Write commit message" },
      { "<leader>cr", "<cmd>CopilotChatRefactor<CR>", desc = "CopilotChat - Refactor code" },
    },
    opts = {
      model = "gpt-4o", -- Get the latest model
      temperature = 0.1, -- Lower temperature for more precise responses
      show_help = true,
      window = {
        layout = "float",
        border = "rounded",
        width = 0.8,
        height = 0.7,
        title = "Copilot Chat",
        footer = nil, 
        zindex = 50,
      },
      
      question_header = "# 󰗶 ",  -- User
      answer_header = "# 󰚩 ",    -- Copilot
      error_header = "# 󰅚 ",     -- Error
      separator = "───",
      
      chat_autocomplete = true,
      clear_chat_on_new_prompt = false,
      
      -- Custom prompts focused on code quality and best practices
      prompts = {
        -- Default prompts with enhancements
        Explain = {
          prompt = [[
            Explain how this code works in a clear, concise manner.
            Focus on:
            1. The purpose and functionality
            2. Core algorithms and techniques used
            3. Any non-obvious design decisions

            Keep your explanation brief and avoid explaining basic concepts unless they're essential.
            Use proper terminology for the language/framework.
          ]],
          system_prompt = "COPILOT_EXPLAIN",
        },
        
        Review = {
          prompt = [[
            Review this code for improvements in the following areas:
            1. Bugs and potential issues
            2. Performance optimizations
            3. Readability and maintainability
            4. Security vulnerabilities
            5. Code style and consistency

            Be specific with your feedback and provide concrete examples.
            Focus on important issues rather than nitpicks.
            Respect the existing code style and patterns.
          ]],
          system_prompt = "COPILOT_REVIEW",
        },
        
        Fix = {
          prompt = [[
            Fix issues in this code, focusing on:
            1. Addressing bugs and logical errors
            2. Maintaining the original intent and behavior
            3. Following language/framework best practices

            Explain your changes clearly but concisely.
            If a fix introduces tradeoffs, explain them briefly.
          ]],
        },
        
        Optimize = {
          prompt = [[
            Optimize this code for better performance and readability, focusing on:
            1. Algorithmic improvements
            2. Memory efficiency
            3. Computational complexity
            4. Modern language features that improve performance

            Explain your optimization approach and the specific benefits.
            Maintain the original functionality while improving efficiency.
          ]],
        },
        
        Docs = {
          prompt = [[
            Add high-quality documentation to this code, focusing on:
            1. Purpose and functionality
            2. Parameters, return values, and exceptions
            3. Examples for non-obvious usage
            4. Follow the documentation style present in the codebase
            5. Keep comments concise - avoid stating the obvious
            
            Document "why" rather than "what" where appropriate.
            Prefer docstrings or standard comment formats for the language.
          ]],
        },
        
        Tests = {
          prompt = [[
            Generate comprehensive tests for this code, focusing on:
            1. Core functionality
            2. Edge cases and error conditions
            3. Integration with related components
            4. Following the testing style/framework used in the project

            Ensure tests are:
            - Readable and maintainable
            - Deterministic where possible
            - Independent of each other
            - Properly named to describe what they're testing
            
            Use mocks or stubs where appropriate for external dependencies.
          ]],
        },
        
        Commit = {
          prompt = [[
            Write a clear commit message for the changes using the Conventional Commits standard.
            The message should:
            1. Start with a type (feat, fix, docs, style, refactor, perf, test, chore)
            2. Have a brief but descriptive title (under 50 chars)
            3. Include relevant details in the body (wrapped at 72 chars)
            4. Reference any relevant issue numbers if applicable

            Format as a git commit message.
          ]],
          context = "git:staged",
        },
        
        -- Custom advanced prompts
        Refactor = {
          prompt = [[
            Refactor this code to improve its structure and design, focusing on:
            1. Applying appropriate design patterns
            2. Improving code organization
            3. Reducing complexity
            4. Enhancing extensibility and maintainability
            
            Keep the same functionality but make the code cleaner and more maintainable.
            Explain your refactoring approach and the benefits it provides.
          ]],
        },
      },
    },
  },
}