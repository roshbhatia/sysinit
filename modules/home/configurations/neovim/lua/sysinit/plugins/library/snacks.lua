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
          enabled = false,
        },
        notifier = {
          enabled = true,
          top_down = true,
          margin = {
            top = 2,
            right = 1,
            bottom = 1,
          },
          style = "minimal",
        },
        picker = {
          enabled = false,
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
          icon = " ",
          icon_hl = "SnacksInputIcon",
          icon_pos = "left",
          prompt_pos = "title",
          win = { style = "input" },
          expand = true,
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
            style = "float",
            width = 0.9,
            height = 0.8,
            border = "rounded",
            title = " Terminal ",
            title_pos = "center",
            backdrop = 80,
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
          },
          input = {
            relative = "cursor",
            row = 1,
            col = 0,
            width = 80,
            border = "rounded",
            title_pos = "center",
            wo = {
              wrap = true,
              linebreak = true,
              relativenumber = true,
              number = true,
            },
          },
        },
      })

      vim.notify = function(msg, level, opts)
        if type(msg) ~= "string" then
          return Snacks.notifier.notify(msg, level, opts or {})
        end

        local ignore_patterns = {
          "^Reloaded %d+ file",
          "failed to run generator",
          "reload buffer",
        }

        for _, pattern in ipairs(ignore_patterns) do
          if msg:find(pattern) then
            return
          end
        end

        return Snacks.notifier.notify(msg, level, opts or {})
      end

      local agents = require("sysinit.plugins.intellicode.agents")
      local ai_manager = require("sysinit.plugins.intellicode.ai.ai_manager")
      local file_refresh = require("sysinit.plugins.intellicode.ai.file_refresh")

      local terminals_config = {}
      for _, agent in ipairs(agents.get_all()) do
        terminals_config[agent.name] = {
          cmd = agent.cmd,
        }
      end

      ai_manager.setup({
        terminals = terminals_config,
        env = {
          PAGER = "bat",
        },
      })

      file_refresh.setup({
        file_refresh = {
          enable = true,
          timer_interval = 1000,
          updatetime = 100,
          show_notifications = true,
        },
      })

      vim.defer_fn(function()
        local blink_ok, blink = pcall(require, "blink.cmp")
        if blink_ok then
          blink.add_source_provider("ai_placeholders", {
            module = "sysinit.plugins.intellicode.ai.completion",
          })
          blink.add_filetype_source("ai_terminals_input", "ai_placeholders")
        end
      end, 100)
    end,
    keys = function()
      local keymaps = require("sysinit.plugins.intellicode.ai.keymaps")
      local ai_keys = keymaps.generate_all_keymaps()

      local default_keys = {

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
                style = "float",
                width = 0.9,
                height = 0.8,
                border = "rounded",
                title = " GitHub CLI ",
                title_pos = "center",
                backdrop = 80,
              },
            })
          end,
          desc = "GitHub: Toggle",
        },
      }
      for _, key in ipairs(ai_keys) do
        table.insert(default_keys, key)
      end

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
