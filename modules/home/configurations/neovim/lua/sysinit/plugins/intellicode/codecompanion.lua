local M = {}
local config = require("sysinit.utils.config")

M.plugins = {
  {
    "olimorris/codecompanion.nvim",
    enabled = config.is_codecompanion_enabled(),
    dependencies = {
      "echasnovski/mini.diff",
      "Davidyz/VectorCode",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    event = "VeryLazy",
    config = function()
      local opts = {
        extensions = {
          vectorcode = {
            opts = {
              tool_group = {
                enabled = true,
                extras = {},
                collapse = false,
              },
              tool_opts = {
                ["*"] = {},
                ls = {},
                vectorise = {},
                query = {
                  max_num = { chunk = -1, document = -1 },
                  default_num = { chunk = 50, document = 10 },
                  include_stderr = false,
                  use_lsp = false,
                  no_duplicate = true,
                  chunk_mode = false,
                  summarise = {
                    enabled = false,
                    adapter = nil,
                    query_augmented = true,
                  },
                },
                files_ls = {},
                files_rm = {},
              },
            },
          },
        },
        strategies = {
          chat = {
            adapter = config.get_codecompanion_adapter(),
          },
          inline = {
            adapter = config.get_codecompanion_adapter(),
          },
          cmd = {
            adapter = config.get_codecompanion_adapter(),
          },
        },
        adapters = {
          acp = {},
        },
        display = {
          action_palette = {
            provider = "telescope",
          },
          chat = {
            intro_message = "Press ? for options...",
            icons = {
              buffer_pin = " ",
              buffer_watch = "󰂥 ",
              chat_context = " ",
              chat_fold = " ",
              tool_pending = " ",
              tool_in_progress = " ",
              tool_failure = " ",
              tool_success = " ",
            },
            window = {
              border = "rounded",
              opts = {
                cursorline = true,
              },
            },
          },
          diff = {
            provider = "mini_diff",
          },
        },
        keymaps = {
          send = {
            modes = {
              n = {
                "CR",
                "<C-CR>",
              },
              i = "<C-CR>",
            },
            index = 2,
            callback = "keymaps.send",
            description = "Send",
          },
        },
      }

      if config.get_codecompanion_adapter() == "claude_code" then
        opts.adapters.acp.claude_code = function()
          return require("codecompanion.adapters").extend("claude_code", {
            env = {
              CLAUDE_CODE_OAUTH_TOKEN = config.get_claude_code_token(),
            },
          })
        end
      end

      require("codecompanion").setup(opts)
    end,
    keys = function()
      return {
        {
          "<leader>kk",
          "<CMD>CodeCompanionChat Toggle<CR>",
          desc = "Toggle chat",
          mode = { "n", "v" },
        },
        {
          "<leader>kK",
          "<CMD>CodeCompanionChat<CR>",
          desc = "New chat",
          mode = { "n", "v" },
        },
        {
          "<leader>ke",
          "<CMD>CodeCompanion<CR>",
          desc = "Inline assistant",
          mode = { "n", "v" },
        },
        {
          "<leader>ka",
          "<CMD>CodeCompanionActions<CR>",
          desc = "Action palette",
          mode = { "n", "v" },
        },
        {
          "<leader>kc",
          "<CMD>CodeCompanionChat Add<CR>",
          desc = "Add current file to chat",
          mode = { "n", "v" },
        },
        {
          "<leader>k/",
          "<CMD>CodeCompanion /explain<CR>",
          desc = "Explain code",
          mode = "v",
        },
        {
          "<leader>k.",
          "<CMD>CodeCompanion /fix<CR>",
          desc = "Fix code",
          mode = "v",
        },
        {
          "<leader>k,",
          "<CMD>CodeCompanion /tests<CR>",
          desc = "Generate tests",
          mode = "v",
        },
        {
          "<leader>kl",
          "<CMD>CodeCompanion /lsp<CR>",
          desc = "Explain LSP diagnostics",
          mode = "v",
        },
        {
          "<leader>k:",
          "<CMD>CodeCompanionCmd<CR>",
          desc = "Generate command",
          mode = "n",
        },
      }
    end,
  },
}

return M
