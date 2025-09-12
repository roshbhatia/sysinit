local config = require("sysinit.utils.config")

local M = {}

M.plugins = {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false,
    dependencies = {
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
      "zbirenbaum/copilot.lua",
    },
    build = "AvanteBuild",
    config = function()
      local avante = require("avante")

      local provider = config.get_avante_provider()
      local opts = {
        provider = provider,
        providers = {
          copilot = {
            model = "gpt-4.1",
          },
        },
        acp_providers = {},
        behaviour = {
          auto_suggestions = false,
        },
        prompt_logger = {
          next_prompt = {
            normal = "<Down>",
            insert = "<Down>",
          },
          prev_prompt = {
            normal = "<Up>",
            insert = "<Up>",
          },
        },
        mappings = {
          submit = {
            normal = "<S-CR>",
            insert = "<CR>",
          },
          ask = "<leader>ha",
          new_ask = "<leader>hH",
          edit = "<leader>he",
          refresh = "<leader>hr",
          focus = "<leader>hf",
          stop = "<leader>hS",
          toggle = {
            default = "<leader>hh",
            debug = "<leader>hd",
            hint = "<leader>hi",
            suggestion = "<leader>hs",
            repomap = "<leader>hR",
          },
          sidebar = {
            switch_windows = "<localleader>[",
            reverse_switch_windows = "<localleader>]",
          },
          files = {
            add_current = "<leader>hc",
            add_all_buffers = "<leader>hB",
          },
          select_model = "<leader>h?",
          select_history = "<leader>hy",
        },
        selector = {
          provider = "telescope",
        },
        input = {
          provider = "snacks",
          provider_opts = {},
        },
        disabled_tools = {
          "web_search",
        },
        windows = {
          sidebar_header = {
            rounded = false,
          },
          input = {
            height = 20,
          },
          edit = {
            border = "rounded",
          },
          ask = {
            floating = true,
            border = "rounded",
          },
          spinner = {
            editing = {
              "-",
              "|",
              "-",
              "|",
              "-",
              "|",
              "-",
              "|",
              "-",
              "|",
            },
            generating = {
              "-",
              "|",
              "-",
              "|",
              "-",
              "|",
              "-",
              "|",
              "-",
              "|",
            },
            thinking = {
              "-",
              "|",
            },
          },
        },
      }

      -- Avoid rate limiting issues w/ native copilot
      if provider == "copilot" then
        opts.mode = "legacy"
      end

      if provider == "claude_code" then
        opts.acp_providers["claude-code"] = {
          command = "npx",
          args = { "@anthropic/claude-code" },
          env = {
            NODE_NO_WARNINGS = "1",
            CLAUDE_CODE_OAUTH_TOKEN = config.get_claude_code_token(),
          },
        }
      elseif provider == "goose" then
        opts.acp_providers["goose"] = {
          command = "goose",
          args = { "acp" },
        }
      end

      avante.setup(opts)

      local augroup = vim.api.nvim_create_augroup("AvanteAutoBufferSelection", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter" }, {
        group = augroup,
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          local bufname = vim.api.nvim_buf_get_name(bufnr)

          if bufname ~= "" then
            pcall(function()
              require("avante.selected_files").add_file(bufname)
            end)
          end
        end,
      })
    end,
  },
}

return M
