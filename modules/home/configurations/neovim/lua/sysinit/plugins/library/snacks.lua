local M = {}

M.plugins = {
  {
    "folke/snacks.nvim",
    priority = 9800,
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("snacks").setup({
        animate = {
          enabled = false,
        },
        bigfile = {
          enabled = true,
        },
        bufdelete = {
          enabled = true,
        },
        lazygit = {
          enabled = true,
          win = {
            style = "lazygit",
          },
        },
        notifier = {
          enabled = true,
          top_down = false,
          margin = {
            top = 2,
            right = 1,
            bottom = 1,
          },
          style = "minimal",
        },
        picker = {
          enabled = true,
          ui_select = false,
          formatters = {
            d = {
              show_always = false,
              unselected = false,
            },
          },
          icons = {
            ui = {
              selected = " ",
              unselected = " ",
            },
          },
        },
        rename = {
          enabled = true,
        },
        scratch = {
          enabled = true,
        },
        statuscolumn = {
          enabled = false,
        },
        words = {
          enabled = true,
        },
        dashboard = {
          enabled = false,
        },
        debug = {
          enabled = false,
        },
        dim = {
          enabled = false,
        },
        explorer = {
          enabled = false,
        },
        git = {
          enabled = false,
        },
        gitbrowse = {
          enabled = false,
        },
        image = {
          enabled = false,
        },
        indent = {
          enabled = false,
        },
        input = {
          enabled = true,
        },
        layout = {
          enabled = false,
        },
        profiler = {
          enabled = true,
        },
        quickfile = {
          enabled = true,
        },
        terminal = {
          enabled = true,
          win = {
            title = "",
            title_pos = "center",
          },
          bo = {
            filetype = "snacks_terminal",
          },
          wo = {
            sidescroll = 0,
          },
        },
        scope = {
          enabled = false,
        },
        scroll = {
          enabled = true,
          animate = {
            duration = { step = 15, total = 150 },
            easing = "outQuad",
          },
          animate_repeat = {
            delay = 50,
            duration = { step = 1, total = 10 },
            easing = "outQuad",
          },
          filter = function(buf)
            return vim.g.snacks_scroll ~= false
              and vim.b[buf].snacks_scroll ~= false
              and vim.bo[buf].buftype ~= "terminal"
          end,
        },
        toggle = {
          enabled = false,
        },
        win = {
          enabled = false,
        },
        zen = {
          enabled = false,
        },
        styles = {
          lazygit = {
            width = 0,
            height = 0,
            backdrop = false,
            wo = {
              winblend = 0,
            },
          },
        },
      })

      vim.ui.input = Snacks.input
      vim.notify = function(msg, level, opts)
        if type(msg) == "string" and (msg:find("^Reloaded %d+ file")) then
          return
        end
        return Snacks.notifier.notify(msg, level, opts or {})
      end
    end,
    keys = function()
      local default_keys = {
        {
          "<leader>gg",
          function()
            Snacks.lazygit()
          end,
          desc = "Toggle git ui",
        },
        {
          "<leader>ns",
          function()
            Snacks.notifier.show_history()
          end,
          desc = "Show notification history",
        },
        {
          "<leader>nc",
          function()
            Snacks.notifier.hide()
          end,
          desc = "Dismiss notification",
        },
        {
          "<Esc><Esc>",
          "<C-\\><C-n>",
          mode = "t",
          desc = "Terminal normal mode",
        },
        {
          "<leader>gG",
          function()
            Snacks.terminal.toggle("gh dash", {
              win = {
                border = "rounded",
                wo = {
                  winblend = 0,
                },
              },
            })
          end,
          desc = "Toggle github ui",
        },
        {
          "<leader>tt",
          function()
            Snacks.terminal.toggle(nil, { cwd = vim.fn.getcwd() })
          end,
          desc = "Toggle terminal (cwd)",
        },
        {
          "<leader>tT",
          function()
            -- Close existing terminal and create new one
            local terms = Snacks.terminal.get()
            if terms and #terms > 0 then
              for _, term in ipairs(terms) do
                if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
                  vim.api.nvim_buf_delete(term.buf, { force = true })
                end
              end
            end
            Snacks.terminal.toggle(nil, { cwd = vim.fn.getcwd() })
          end,
          desc = "Recreate terminal",
        },
      }

      if vim.env.SYSINIT_DEBUG ~= "1" then
        return default_keys
      end

      local debug_keys = {
        {
          "<leader>px",
          function()
            Snacks.profiler.stop()
          end,
          desc = "Stop profiler",
        },
        {
          "<leader>pf",
          function()
            Snacks.profiler.pick()
          end,
          desc = "Find profiler events",
        },
        {
          "<leader>pp",
          function()
            Snacks.toggle.profiler()
          end,
          desc = "Toggle profiler",
        },
        {
          "<leader>ph",
          function()
            Snacks.toggle.profiler_highlights()
          end,
          desc = "Toggle profiler highlights",
        },
        {
          "<leader>ps",
          function()
            Snacks.profiler.scratch()
          end,
          desc = "Toggle profiler scratch buffer",
        },
      }

      for _, key in ipairs(debug_keys) do
        table.insert(default_keys, key)
      end

      return default_keys
    end,
  },
}

return M
