local M = {}

M.plugins = {
  {
    enabled = not vim.uv.fs_stat(vim.fn.expand("~/.nocopilot")),
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false,
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
      "zbirenbaum/copilot.lua",
      "MeanderingProgrammer/render-markdown.nvim",
      "ravitemer/mcphub.nvim",
    },
    config = function()
      local avante = require("avante")
      avante.setup({
        provider = "copilot",
        mode = "agentic",
        providers = {
          copilot = {
            model = "gemini-2.0-flash-001",
          },
        },
        behaviour = {
          auto_suggestions = false,
        },
        prompt_logger = {
          next_prompt = {
            normal = "j",
            insert = "<Down>",
          },
          prev_prompt = {
            normal = "h",
            insert = "<Up>",
          },
        },
        mappings = {
          submit = {
            normal = "<CR>",
            insert = "<S-CR>",
          },
          ask = "<leader>ha",
          new_ask = "<leader>hA",
          toggle = {
            default = "<leader>hh",
            suggestion = "<leader>h\\",
          },
          sidebar = {
            switch_windows = "<C-Tab>",
            reverse_switch_windows = "<C-S-Tab>",
          },
        },
        selector = {
          provider = "telescope",
        },
        system_prompt = function()
          local hub = require("mcphub").get_hub_instance()
          return hub and hub:get_active_servers_prompt() or ""
        end,
        custom_tools = function()
          return {
            require("mcphub.extensions.avante").mcp_tool(),
          }
        end,
        disabled_tools = {
          -- Disabled due to conflicts with mcphub
          "list_files",
          "search_files",
          "replace_in_file",
          "read_file",
          "create_file",
          "rename_file",
          "delete_file",
          "create_dir",
          "rename_dir",
          "delete_dir",
          "bash",
          -- Disabled due to lack of use in favor with fetch
          "web_search",
        },
        windows = {
          sidebar_header = {
            rounded = false,
          },
          input = {
            height = 24,
          },
          edit = {
            border = {
              "╭",
              "─",
              "╮",
              "│",
              "╯",
              "─",
              "╰",
              "│",
            },
          },
          ask = {
            border = {
              "╭",
              "─",
              "╮",
              "│",
              "╯",
              "─",
              "╰",
              "│",
            },
          },
        },
      })

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

      vim.api.nvim_create_autocmd("FileType", {
        group = augroup,
        pattern = "Avante",
        callback = function()
          vim.opt_local.foldcolumn = "0"
          vim.opt_local.foldtext = ""
          vim.opt_local.foldmethod = "manual"
        end,
      })
    end,
  },
}

return M
