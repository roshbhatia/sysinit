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
          wo = {},
          keys = {
            q = "hide",
            gf = function(self)
              local f = vim.fn.findfile(vim.fn.expand("<cfile>"), "**")
              if f == "" then
                Snacks.notify.warn("No file under cursor")
              else
                self:hide()
                vim.schedule(function()
                  vim.cmd("e " .. f)
                end)
              end
            end,
            term_normal = {
              "<esc>",
              function(self)
                self.esc_timer = self.esc_timer or (vim.uv or vim.loop).new_timer()
                if self.esc_timer:is_active() then
                  self.esc_timer:stop()
                  vim.cmd("stopinsert")
                else
                  self.esc_timer:start(200, 0, function() end)
                  return "<esc>"
                end
              end,
              mode = "t",
              expr = true,
              desc = "Escape escape normal mode",
            },
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
      })

      vim.notify = Snacks.notifier.notify
      vim.ui.input = Snacks.input
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
