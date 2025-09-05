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
        adapters = {},
        display = {
          action_palette = {
            provider = "telescope",
          },
          chat = {
            icons = {
              buffer_pin = " ",
              buffer_watch = " ",
            },
          },
          diff = {
            provider = "mini_diff",
          },
        },
        keymaps = {
          send = {
            modes = {
              n = "<localleader>ks",
              v = "<localleader>ks",
              i = "<localleader>ks",
            },
            index = 2,
            callback = "keymaps.send",
            description = "Send",
          },
          options = {
            modes = {
              n = "<localleader>ko",
            },
            callback = "keymaps.options",
            description = "Options",
          },
          completion = {
            modes = {
              i = "<localleader>kc",
            },
            index = 1,
            callback = "keymaps.completion",
            description = "Completion Menu",
          },
          regenerate = {
            modes = {
              n = "<localleader>kr",
            },
            index = 3,
            callback = "keymaps.regenerate",
            description = "Regenerate the last response",
          },
          close = {
            modes = {
              n = "<localleader>kx",
              i = "<localleader>kx",
            },
            index = 4,
            callback = "keymaps.close",
            description = "Close Chat",
          },
          stop = {
            modes = {
              n = "<localleader>kq",
            },
            index = 5,
            callback = "keymaps.stop",
            description = "Stop Request",
          },
          clear = {
            modes = {
              n = "<localleader>kd",
            },
            index = 6,
            callback = "keymaps.clear",
            description = "Clear Chat",
          },
          codeblock = {
            modes = {
              n = "<localleader>kb",
            },
            index = 7,
            callback = "keymaps.codeblock",
            description = "Insert Codeblock",
          },
          yank_code = {
            modes = {
              n = "<localleader>ky",
            },
            index = 8,
            callback = "keymaps.yank_code",
            description = "Yank Code",
          },
          pin = {
            modes = {
              n = "<localleader>kp",
            },
            index = 9,
            callback = "keymaps.pin_context",
            description = "Pin context",
          },
          watch = {
            modes = {
              n = "<localleader>kw",
            },
            index = 10,
            callback = "keymaps.toggle_watch",
            description = "Watch Buffer",
          },
          next_chat = {
            modes = {
              n = "<localleader>kn",
            },
            index = 11,
            callback = "keymaps.next_chat",
            description = "Next Chat",
          },
          previous_chat = {
            modes = {
              n = "<localleader>kN",
            },
            index = 12,
            callback = "keymaps.previous_chat",
            description = "Previous Chat",
          },
          next_header = {
            modes = {
              n = "<localleader>kh",
            },
            index = 13,
            callback = "keymaps.next_header",
            description = "Next Header",
          },
          previous_header = {
            modes = {
              n = "<localleader>kH",
            },
            index = 14,
            callback = "keymaps.previous_header",
            description = "Previous Header",
          },
          change_adapter = {
            modes = {
              n = "<localleader>ka",
            },
            index = 15,
            callback = "keymaps.change_adapter",
            description = "Change adapter",
          },
          fold_code = {
            modes = {
              n = "<localleader>kf",
            },
            index = 16,
            callback = "keymaps.fold_code",
            description = "Fold code",
          },
          debug = {
            modes = {
              n = "<localleader>kD",
            },
            index = 17,
            callback = "keymaps.debug",
            description = "View debug info",
          },
          system_prompt = {
            modes = {
              n = "<localleader>kS",
            },
            index = 18,
            callback = "keymaps.toggle_system_prompt",
            description = "Toggle the system prompt",
          },
          yolo_mode = {
            modes = {
              n = "<localleader>kY",
            },
            index = 19,
            callback = "keymaps.yolo_mode",
            description = "YOLO mode toggle",
          },
          goto_file_under_cursor = {
            modes = {
              n = "<localleader>kR",
            },
            index = 20,
            callback = "keymaps.goto_file_under_cursor",
            description = "Open the file under cursor in a new tab.",
          },
          copilot_stats = {
            modes = {
              n = "<localleader>kU",
            },
            index = 21,
            callback = "keymaps.copilot_stats",
            description = "Show Copilot usage statistics",
          },
          super_diff = {
            modes = {
              n = "<localleader>kM",
            },
            index = 22,
            callback = "keymaps.super_diff",
            description = "Show Super Diff",
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
