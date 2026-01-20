return {
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
          enabled = true,
          matcher = {
            frecency = true,
            history_bonus = true,
          },
          sources = {
            files = {
              hidden = true,
              ignored = false,
            },
          },
          formatters = {
            files = { filename_first = true },
          },
          win = {
            input = {
              keys = {
                ["<Tab>"] = { "list_down", mode = { "i", "n" } },
                ["<S-Tab>"] = { "list_up", mode = { "i", "n" } },
                ["<localleader>s"] = "edit_split",
                ["<localleader>v"] = "edit_vsplit",
              },
            },
            list = {
              keys = {
                ["j"] = "list_down",
                ["k"] = "list_up",
              },
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
          enabled = true,
          preset = {
            keys = {
              { icon = "󱡂 ", key = "f", desc = "Find File", action = ":lua Snacks.picker.files()" },
              { icon = "󰓥 ", key = "g", desc = "Grep string", action = ":lua Snacks.picker.grep()" },
              { icon = "󱡃 ", key = "i", desc = "New file", action = ":ene | startinsert" },
              { icon = "󰄚 ", key = "q", desc = "Quit", action = ":qa" },
            },
            header = [[
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⣴⢋⣔⣶⣿⢋⣙⣳⣤⣀⣠⣤⠐⠄⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⣿⡾⣿⣿⣿⣿⣿⣿⣿⣬⣥⣤⣠⡦⠖⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⣿⣿⣿⣿⣿⣿⣿⣿⡟⠛⠆⢀⠀⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣤⣄⣠⣤⣄⠄⡀⢠⣯⣿⣿⣿⣿⣿⣿⣾⣷⣤⢔⣊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣾⣽⣧⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣭⡟⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⢀⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡗⠀⠻⢿⣿⣉⠛⢻⣿⠉⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠸⠀⠀⣼⢯⣿⣿⣿⣿⣿⣿⣿⣻⣿⣿⣿⢿⣿⣿⣷⠠⢠⢏⣿⠉⠉⠩⠛⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢀⠄⠀⠓⣶⣯⣿⣿⣿⣿⣟⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⣇⣚⡁⠀⠁⢠⠀⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠈⠃⡀⠀⣿⣿⣿⣿⣿⣟⣿⣯⣷⣻⣽⣿⣯⣟⢻⣻⣿⣿⣿⣷⢶⠞⢗⣲⣄⡤⡂⠉⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⣹⠛⠏⢳⡀⠹⣿⣿⣿⣿⣿⣿⣿⣯⣤⣝⣿⣿⣿⣿⣿⣶⣷⣟⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣦⡿⠋⣗⠤⢹⡜⢛⠻⣿⣿⣷⣾⣿⣯⣧⡽⣿⣿⣿⣿⣷⣍⢳⢥⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡗⠍⣅⣴⣿⣄⡘⠆⠈⠨⡌⢻⣿⡗⣬⣼⢟⣫⡾⢿⣿⣿⣿⣿⡿⡄⢮⣆⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢠⠦⢀⡀⠀⠀⠀⢇⢸⡭⠓⠁⠁⠜⠈⠄⠀⠱⡀⢻⣿⣾⡤⢼⣿⣖⣿⣿⣿⣿⣿⣷⡆⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⢀⣔⣋⣥⢋⢹⡀⠀⠀⢰⢸⢀⢴⣀⣤⠦⠀⠨⠃⠀⠒⢮⣿⣵⣧⣸⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⡄⠄⠀⠀⠀⠀⠀⠀⠀
⠀⣀⡆⡎⡀⠀⠀⠀⠀⠀⠀⠰⠀⠸⠀⠷⣶⣆⣶⡆⠀⠀⣀⣿⡿⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⠀⠀⠀⣰⠆⢀⡀⠆⠀⠀⠀⠀
⠀⢕⣿⢀⣱⠪⢧⢻⠇⢀⠀⠀⠀⠀⠀⠀⠙⠯⡄⣙⣧⢤⣷⠿⣿⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠛⣴⣵⡿⣣⢨⠄⠀⠀
⢰⡆⡜⡎⠁⠀⢰⠒⣾⢠⡄⠀⠀⠀⠀⠀⠀⠀⠸⢿⣿⠿⠁⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⢦⣗⣈⢻⣄⡟⠅⣀⢠⡄
⠀⢿⠀⠐⢠⣆⠲⡶⡗⠱⡇⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠩⣽⣿⣿⡳⣿⢴⡿⠅
⢰⢘⠀⢻⡄⢧⠸⣗⡧⢄⣾⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⢠⣟⣾⡇⢹⠓⠀⠀
⠈⡈⡀⠀⠁⡈⠚⣿⣉⣓⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⠾⠃⣯⠀⡀⠀
⠀⢳⣤⡀⠀⢰⠀⠻⣿⡿⠀⠀⠀⠀⠀⠀⠀⢀⠀⢠⠎⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣳⠆⢱⡇⠘⣄
⠀⠈⠿⠹⠆⢀⡆⠈⠁⡇⠀⠀⠀⠀⠀⠀⡞⠃⣿⡏⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠻⢠⠀⡇⡀⢚
⠀⠀⠀⣼⠀⠸⠅⠀⠀⢺⠀⠀⠀⠀⠀⣼⡷⢋⣼⢷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⢾⣧⢰⠃⢠
⠀⠀⢀⠫⠀⣆⠀⠀⠀⢚⠄⠀⠀⠀⠀⠛⣠⠋⢸⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⣻⡆⠘⠄⠈
⠀⠀⢀⡀⠇⠀⠀⡀⠀⣿⡸⣤⣤⣀⠀⢸⣧⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣻⣇⢠⠀⡀
⠀⠀⣸⡇⢠⠀⠀⢠⠃⠘⣽⣿⣿⣿⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡗⢙⣮⠂⠀⠀
⠀⢰⣿⣿⣈⠀⠀⠠⠷⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠲⠄⢃⠀⠀
⠀⠘⣿⣿⣿⡄⠀⠀⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⠁⠀⠀⠀⠀
⠀⠀⣿⣿⣿⣧⣰⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢂⠂⡀⠀⠀⠀]],
          },
          sections = {
            { section = "header" },
            { section = "keys", gap = 1, padding = 1 },
            { section = "startup" },
          },
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
            wo = {
              winblend = 10,
            },
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

      local agents = require("sysinit.utils.ai.agents")
      local session = require("sysinit.utils.ai.session")
      local completion = require("sysinit.utils.ai.completion")
      local file_refresh = require("sysinit.utils.ai.file_refresh")

      completion.setup()

      local terminals_config = {}
      for _, agent in ipairs(agents.get_all()) do
        terminals_config[agent.name] = {
          cmd = agent.cmd,
        }
      end

      session.setup({
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
    end,
    keys = function()
      local keymaps = require("sysinit.utils.ai.keymaps")
      local ai_keys = keymaps.generate_all_keymaps()

      local default_keys = {
        {
          "<leader>fr",
          function()
            Snacks.picker.grep()
          end,
          desc = "Grep (alt.)",
        },
        {
          "<leader>fu",
          function()
            Snacks.picker.undo()
          end,
          desc = "Undo history",
        },
        {
          "<leader>?",
          function()
            Snacks.picker.commands({ layout = "ivy", preview = false })
          end,
          desc = "Commands",
        },
        {
          "<leader>fb",
          function()
            Snacks.picker.buffers({
              layout = "vscode",
              sort_mru = true,
              current = true,
            })
          end,
          desc = "Buffers",
        },
        {
          "<leader>fd",
          function()
            Snacks.picker.diagnostics({ layout = "ivy" })
          end,
          desc = "Diagnostics",
        },
        {
          "<leader>ff",
          function()
            Snacks.picker.files({
              hidden = true,
              ignored = false,
            })
          end,
          desc = "Files",
        },
        {
          "<leader>fj",
          function()
            Snacks.picker.jumps({ layout = "ivy" })
          end,
          desc = "Jumplist",
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
                style = "float",
                width = 0.9,
                height = 0.8,
                border = "rounded",
                title = " GitHub CLI ",
                title_pos = "center",
                backdrop = 80,
                wo = { winblend = 10 },
              },
            })
          end,
          desc = "Toggle",
        },
      }
      for _, key in ipairs(ai_keys) do
        table.insert(default_keys, key)
      end

      return default_keys
    end,
  },
}
