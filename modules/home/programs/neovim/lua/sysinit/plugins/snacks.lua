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
        bigfile = { enabled = true },
        bufdelete = { enabled = true },
        picker = {
          matcher = {
            frecency = true,
            history_bonus = true,
          },
          sources = {
            files = {
              hidden = true,
              ignored = false,
              follow = true, -- follow symlinks by default for files picker
              -- make files picker larger by default (cover more of the screen)
              layout = {
                -- `layout.layout` mirrors the example shape used by snacks for per-source overrides
                layout = {
                  -- relative width (0-1) or absolute columns depending on layout resolver
                  width = 0.95,
                  height = 0.95,
                },
              },
            },
            grep = {
              hidden = true,
              ignored = false,
              follow = true, -- follow symlinks by default for files picker
              -- make files picker larger by default (cover more of the screen)
              layout = {
                -- `layout.layout` mirrors the example shape used by snacks for per-source overrides
                layout = {
                  -- relative width (0-1) or absolute columns depending on layout resolver
                  width = 0.95,
                  height = 0.95,
                },
              },
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
                -- prefer localleader for follow/maximize toggles (Alt/Ctrl often captured by terminals)
                ["<localleader>f"] = { "toggle_follow", mode = { "i", "n" } },
                ["<localleader>m"] = { "toggle_maximize", mode = { "i", "n" } },
              },
            },
            list = {
              keys = {
                ["/"] = "toggle_focus",
                ["<2-LeftMouse>"] = "confirm",
                ["<CR>"] = "confirm",
                ["<Down>"] = "list_down",
                ["<Esc>"] = "cancel",
                ["<S-CR>"] = { { "pick_win", "jump" } },
                ["<S-Tab>"] = { "select_and_prev", mode = { "n", "x" } },
                ["<Tab>"] = { "select_and_next", mode = { "n", "x" } },
                ["<Up>"] = "list_up",
                -- avoid Alt/Ctrl combos; prefer localleader or plain keys
                ["d"] = "inspect",
                ["<localleader>f"] = "toggle_follow",
                ["<localleader>h"] = "toggle_hidden",
                ["<localleader>i"] = "toggle_ignored",
                ["<localleader>m"] = "toggle_maximize",
                ["<localleader>p"] = "toggle_preview",
                ["<localleader>w"] = "cycle_win",
                ["<localleader>a"] = "select_all",
                ["<localleader>B"] = "preview_scroll_up",
                ["<localleader>d"] = "list_scroll_down",
                ["<localleader>F"] = "preview_scroll_down",
                ["<localleader>q"] = "qflist",
                ["<localleader>g"] = "print_path",
                ["<localleader>s"] = "edit_split",
                ["<localleader>t"] = "tab",
                ["<localleader>u"] = "list_scroll_up",
                ["<localleader>v"] = "edit_vsplit",
                ["?"] = "toggle_help_list",
                ["G"] = "list_bottom",
                ["gg"] = "list_top",
                ["i"] = "focus_input",
                ["j"] = "list_down",
                ["k"] = "list_up",
                ["q"] = "cancel",
                ["zb"] = "list_scroll_bottom",
                ["zt"] = "list_scroll_top",
                ["zz"] = "list_scroll_center",
              },
              wo = {
                conceallevel = 2,
                concealcursor = "nvc",
              },
            },
            -- preview window keybindings
            preview = {
              keys = {
                ["<Esc>"] = "cancel",
                ["q"] = "cancel",
                ["i"] = "focus_input",
                ["<localleader>w"] = "cycle_win",
              },
            },
          },
        },
        image = {
          enabled = true,
        },
        dashboard = {
          enabled = true,
          preset = {
            keys = {
              {
                icon = "󱡂 ",
                key = "f",
                desc = "Find File",
                action = function()
                  Snacks.picker.files()
                end,
              },
              {
                icon = "󰓥 ",
                key = "g",
                desc = "Grep string",
                action = function()
                  Snacks.picker.grep()
                end,
              },
              { icon = "󱡃 ", key = "i", desc = "New file", action = ":ene | startinsert" },
              { icon = "󰄚 ", key = "g", desc = "Git", action = ":Neogit" },
              { icon = " ", key = "q", desc = "Quit", action = ":qa" },
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
          },
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
        quickfile = {
          enabled = true,
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
        words = {
          enabled = true,
        },
      })

      local agents = require("sysinit.utils.ai.agents")
      local session = require("sysinit.utils.ai.session")
      local completion = require("sysinit.utils.ai.completion")
      local file_refresh = require("sysinit.utils.ai.file_refresh")

      completion.setup()

      local terminals_config = {}
      for _, agent in ipairs(agents.get_all()) do
        terminals_config[agent.name] = {
          cmd = agent.full_cmd,
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

      -- Fix for snacks dashboard autocommand group cleanup error
      -- Safely handle autocommand group deletion to prevent E367 errors
      local safe_delete_augroup = function(group_id)
        if group_id and group_id > 0 then
          local ok, err = pcall(function()
            vim.api.nvim_del_augroup_by_id(group_id)
          end)
          if not ok and err:find("No such group") then
            -- Group already deleted or doesn't exist, silently ignore
            return true
          end
          return ok
        end
        return true
      end

      -- Override snacks dashboard cleanup to use safe deletion
      local original_delete_augroup = vim.api.nvim_del_augroup_by_id
      vim.api.nvim_del_augroup_by_id = function(group_id)
        return safe_delete_augroup(group_id) or original_delete_augroup(group_id)
      end
    end,
    keys = function()
      local keymaps = require("sysinit.utils.ai.keymaps")
      local ai_keys = keymaps.generate_all_keymaps()

      local default_keys = {
        -- Pickers
        {
          "<leader>ff",
          function()
            Snacks.picker.files()
          end,
          desc = "Files",
        },
        {
          "<leader>fg",
          function()
            Snacks.picker.grep()
          end,
          desc = "Grep",
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
          "<leader>fu",
          function()
            Snacks.picker.undo()
          end,
          desc = "Undo history",
        },
        {
          "<leader>fr",
          function()
            Snacks.picker.resume()
          end,
          desc = "Last picker",
        },
        {
          "<leader>fj",
          function()
            Snacks.picker.jumps({ layout = "top" })
          end,
          desc = "Jumplist",
        },
        -- LSP
        {
          "<leader>cfd",
          function()
            Snacks.picker.lsp_definitions()
          end,
          desc = "LSP definitions",
        },
        {
          "<leader>cfD",
          function()
            Snacks.picker.lsp_declarations()
          end,
          desc = "LSP declarations",
        },
        {
          "<leader>cfr",
          function()
            Snacks.picker.lsp_references()
          end,
          desc = "References",
          nowait = true,
        },
        {
          "<leader>cfi",
          function()
            Snacks.picker.lsp_implementations()
          end,
          desc = "Implementations",
        },
        {
          "<leader>cfy",
          function()
            Snacks.picker.lsp_type_definitions()
          end,
          desc = "Type definition",
        },
        {
          "<leader>cfI",
          function()
            Snacks.picker.lsp_incoming_calls()
          end,
          desc = "Incoming calls",
        },
        {
          "<leader>cfo",
          function()
            Snacks.picker.lsp_outgoing_calls()
          end,
          desc = "Outgoing calls",
        },
        {
          "<leader>cfs",
          function()
            Snacks.picker.lsp_symbols({ layout = "bottom" })
          end,
          desc = "Document symbols",
        },
        {
          "<leader>cfS",
          function()
            Snacks.picker.lsp_workspace_symbols({ layout = "bottom" })
          end,
          desc = "Workspace symbols",
        },
        {
          "<leader>cft",
          desc = "AST Grep",
          function()
            Snacks.picker.pick({
              title = "AST Grep",
              format = "file",
              notify = false,
              show_empty = true,
              live = true,
              supports_live = true,
              finder = function(opts, ctx)
                local cmd = "ast-grep"
                local args = { "run", "--color=never", "--json=stream", "--no-ignore=hidden" }
                local pattern, pargs = Snacks.picker.util.parse(ctx.filter.search)
                table.insert(args, string.format("--pattern=%s", pattern))
                vim.list_extend(args, pargs)
                opts = vim.tbl_extend("force", opts, {
                  cmd = cmd,
                  args = args,
                  transform = function(item)
                    local entry = vim.json.decode(item.text)
                    if vim.tbl_isempty(entry) then
                      return false
                    end
                    local start = entry.range.start
                    item.cwd = vim.fs.normalize(opts and opts.cwd or vim.uv.cwd() or ".") or nil
                    item.file = entry.file
                    item.line = entry.line
                    item.pos = { tonumber(start.line) + 1, tonumber(start.column) }
                    return true
                  end,
                })
                return require("snacks.picker.source.proc").proc(opts, ctx)
              end,
            })
          end,
        },
        {
          "<leader>cfx",
          function()
            Snacks.picker.diagnostics()
          end,
          desc = "Workspace diagnostics",
        },
        {
          "<leader>cfb",
          function()
            Snacks.picker.diagnostics({ buf = 0 })
          end,
          desc = "Buffer diagnostics",
        },
        {
          "]]",
          function()
            Snacks.words.jump(vim.v.count1)
          end,
          desc = "Next Reference",
          mode = { "n", "t" },
        },
        {
          "[[",
          function()
            Snacks.words.jump(-vim.v.count1)
          end,
          desc = "Prev Reference",
          mode = { "n", "t" },
        },
      }
      for _, key in ipairs(ai_keys) do
        table.insert(default_keys, key)
      end

      return default_keys
    end,
  },
}
