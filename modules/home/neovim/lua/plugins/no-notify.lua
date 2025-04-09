-- Disable nvim-notify but provide a minimal replacement
return {
  -- Disable original nvim-notify
  {
    "rcarriga/nvim-notify",
    enabled = false,
  },

  -- Modify noice to work without nvim-notify
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    opts = {
      notify = {
        -- Disable the nvim-notify backend
        enabled = false,
      },
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
      },
      messages = {
        enabled = true,
        -- Use mini view for messages
        view = "mini",
        view_error = "mini",
        view_warn = "mini",
      },
      cmdline = {
        format = {
          search_down = {
            view = "cmdline",
          },
          search_up = {
            view = "cmdline",
          },
        },
      },
      views = {
        mini = {
          timeout = 3000,
          position = {
            row = -2,
          },
          border = {
            style = "rounded",
          },
          win_options = {
            winblend = 0,
          },
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
      },
    },
    keys = {
      { "<leader>nd", function() require("noice").cmd("dismiss") end, desc = "Dismiss Notifications" },
    }
  }
}
