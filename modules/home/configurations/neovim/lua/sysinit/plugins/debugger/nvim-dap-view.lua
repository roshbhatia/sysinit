local M = {}

M.plugins = {
  {
    "igorlfs/nvim-dap-view",
    cmd = "DapViewToggle",
    config = function()
      local views = require("dap-view.views")

      require("dap-view").setup({
        winbar = {
          base_sections = {
            breakpoints = {
              keymap = "<localleader>b",
              label = "Breakpoints [\\b]",
              short_label = " [B]",
              action = function()
                views.switch_to_view("breakpoints")
              end,
            },
            scopes = {
              keymap = "<localleader>s",
              label = "Scopes [\\s]",
              short_label = "󰂥 [s]",
              action = function()
                views.switch_to_view("scopes")
              end,
            },
            exceptions = {
              keymap = "<localleader>e",
              label = "Exceptions [\\e]",
              short_label = "󰢃 [e]",
              action = function()
                views.switch_to_view("exceptions")
              end,
            },
            watches = {
              keymap = "<localleader>w",
              label = "Watches [\\w]",
              short_label = "󰛐 [w]",
              action = function()
                views.switch_to_view("watches")
              end,
            },
            threads = {
              keymap = "<localleader>t",
              label = "Threads [\\t]",
              short_label = "󱉯 [t]",
              action = function()
                views.switch_to_view("threads")
              end,
            },
            repl = {
              keymap = "<localleader>r",
              label = "REPL [\\r]",
              short_label = "󰯃 [r]",
              action = function()
                require("dap-view.repl").show()
              end,
            },
            sessions = {
              keymap = "<localleader>k",
              label = "Sessions [\\k]",
              short_label = " [k]",
              action = function()
                views.switch_to_view("sessions")
              end,
            },
            console = {
              keymap = "<localleader>c",
              label = "Console [\\c]",
              short_label = "󰆍 [c]",
              action = function()
                require("dap-view.term").show()
              end,
            },
          },
        },
      })
    end,
    keys = function()
      return {
        {
          "<leader>dd",
          function()
            vim.cmd("DapViewToggle")
          end,
          desc = "Toggle dap view",
        },
      }
    end,
  },
}

return M
