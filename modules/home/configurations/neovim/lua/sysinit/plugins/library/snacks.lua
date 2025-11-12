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
          sources = {
            gh_issue = {},
            gh_pr = {},
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
        gh = {
          enabled = true,
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
        {
          "<leader>yi",
          function()
            Snacks.picker.gh_issue()
          end,
          desc = "GitHub Issues (open)",
        },
        {
          "<leader>yI",
          function()
            Snacks.picker.gh_issue({ state = "all" })
          end,
          desc = "GitHub Issues (all)",
        },
        {
          "<leader>yp",
          function()
            Snacks.picker.gh_pr()
          end,
          desc = "GitHub Pull Requests (open)",
        },
        {
          "<leader>yP",
          function()
            Snacks.picker.gh_pr({ state = "all" })
          end,
          desc = "GitHub Pull Requests (all)",
        },
        {
          "<leader>yd",
          function()
            vim.ui.input({ prompt = "PR number:" }, function(input)
              if input and tonumber(input) then
                Snacks.picker.gh_diff({ pr = tonumber(input) })
              else
                Snacks.notify.warn("Invalid PR number")
              end
            end)
          end,
          desc = "GitHub PR diff",
        },
        {
          "<leader>yy",
          function()
            local last = vim.b.snacks_last_github_picker
            if last == "pr" then
              Snacks.picker.gh_issue()
              vim.b.snacks_last_github_picker = "issue"
            else
              Snacks.picker.gh_pr()
              vim.b.snacks_last_github_picker = "pr"
            end
          end,
          desc = "GitHub toggle (issue <-> PR)",
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
