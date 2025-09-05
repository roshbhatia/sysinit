local M = {}
local config = require("sysinit.utils.config")

M.plugins = {
  {
    "olimorris/codecompanion.nvim",
    enabled = config.is_codecompanion_enabled(),
    dependencies = {
      "Davidyz/VectorCode",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/codecompanion-history.nvim",
    },
    event = "VeryLazy",
    config = function()
      local opts = {
        adapters = {
          acp = {},
        },
        display = {
          action_palette = {
            provider = "telescope",
          },
          chat = {
            intro_message = "Press ? for options...",
            window = {
              border = "rounded",
              opts = {
                cursorline = true,
              },
            },
          },
          diff = {
            provider = "inline",
          },
        },
        extensions = {
          history = {
            auto_generate_title = true,
            auto_save = true,
            chat_filter = nil,
            continue_last_chat = false,
            delete_on_clearing_chat = false,
            dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
            enable_logging = false,
            enabled = true,
            expiration_days = 0,
            keymap = "gh",
            memory = {
              auto_create_memories_on_summary_generation = true,
              index_on_startup = true,
              notify = true,
              tool_opts = {
                default_num = 10,
              },
              vectorcode_exe = "vectorcode",
            },
            opts = {
              auto_generate_title = true,
              auto_save = true,
              chat_filter = nil,
              continue_last_chat = false,
              delete_on_clearing_chat = false,
              dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
              enable_logging = false,
              expiration_days = 0,
              keymap = "gh",
              memory = {
                auto_create_memories_on_summary_generation = true,
                index_on_startup = true,
                notify = true,
                tool_opts = {
                  default_num = 10,
                },
                vectorcode_exe = "vectorcode",
              },
              picker = "telescope",
              picker_keymaps = {
                delete = { n = "d", i = "<M-d>" },
                duplicate = { n = "<C-y>", i = "<C-y>" },
                rename = { n = "r", i = "<M-r>" },
              },
              save_chat_keymap = "sc",
              summary = {
                browse_summaries_keymap = "gbs",
                create_summary_keymap = "gcs",
                generation_opts = {
                  adapter = nil,
                  context_size = 90000,
                  format_summary = nil,
                  include_references = true,
                  include_tool_outputs = true,
                  model = nil,
                  system_prompt = nil,
                },
              },
              title_generation_opts = {
                adapter = nil,
                format_title = function(original_title)
                  return original_title
                end,
                max_refreshes = 3,
                model = nil,
                refresh_every_n_prompts = 0,
              },
            },
            picker = "telescope",
            picker_keymaps = {
              delete = { n = "d", i = "<M-d>" },
              duplicate = { n = "<C-y>", i = "<C-y>" },
              rename = { n = "r", i = "<M-r>" },
            },
            save_chat_keymap = "sc",
            summary = {
              browse_summaries_keymap = "gbs",
              create_summary_keymap = "gcs",
              generation_opts = {
                adapter = nil,
                context_size = 90000,
                format_summary = nil,
                include_references = true,
                include_tool_outputs = true,
                model = nil,
                system_prompt = nil,
              },
            },
            title_generation_opts = {
              adapter = nil,
              format_title = function(original_title)
                return original_title
              end,
              max_refreshes = 3,
              model = nil,
              refresh_every_n_prompts = 0,
            },
          },
          vectorcode = {
            opts = {
              tool_group = {
                collapse = false,
                enabled = true,
                extras = {},
              },
              tool_opts = {
                ["*"] = {},
                files_ls = {},
                files_rm = {},
                ls = {},
                query = {
                  chunk_mode = false,
                  default_num = { chunk = 50, document = 10 },
                  include_stderr = false,
                  max_num = { chunk = -1, document = -1 },
                  no_duplicate = true,
                  summarise = {
                    adapter = nil,
                    enabled = false,
                    query_augmented = true,
                  },
                  use_lsp = false,
                },
                vectorise = {},
              },
            },
          },
        },
        keymaps = {
          send = {
            callback = "keymaps.send",
            description = "Send",
            index = 2,
            modes = {
              n = {
                "CR",
                "<C-CR>",
              },
              i = "<C-CR>",
            },
          },
        },
        strategies = {
          chat = {
            adapter = config.get_codecompanion_adapter(),
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
          "<leader>kt",
          "<CMD>CodeCompanion /tests<CR>",
          desc = "Generate tests for selection",
          mode = "v",
        },
        {
          "<leader>kf",
          "<CMD>CodeCompanion /fix<CR>",
          desc = "Fix diagnostics within selection",
          mode = "v",
        },
        {
          "<leader>ke",
          "<CMD>CodeCompanion /explain<CR>",
          desc = "Explain selection",
          mode = "v",
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
          desc = "Add selection to chat",
          mode = { "v" },
        },
        {
          "<leader>kk",
          "<CMD>CodeCompanionChat Toggle<CR>",
          desc = "Toggle chat",
          mode = { "n" },
        },
        {
          "<leader>kK",
          "<CMD>CodeCompanionChat<CR>",
          desc = "New chat",
          mode = { "n" },
        },
        {
          "<leader>kl",
          "<CMD>CodeCompanion /lsp<CR>",
          desc = "Explain diagnostics within selection",
          mode = "v",
        },
      }
    end,
  },
}

return M
