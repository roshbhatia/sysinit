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
              layout = {
                layout = {
                  width = 0.95,
                  height = 0.95,
                },
              },
            },
            grep = {
              hidden = true,
              ignored = false,
              follow = true, -- follow symlinks by default for files picker
              layout = {
                layout = {
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
              { icon = "󰄚 ", key = "n", desc = "Git", action = ":Neogit" },
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
            if
              vim.g.snacks_scroll == false
              or vim.b[buf].snacks_scroll == false
              or vim.bo[buf].buftype == "terminal"
            then
              return false
            end
            -- A diff pair is scroll-bound. Snacks animates only the current
            -- window of a bound pair, so the other one jumps and the two
            -- halves drift apart mid-animation.
            for _, win in ipairs(vim.fn.win_findbuf(buf)) do
              if vim.wo[win].diff then
                return false
              end
            end
            return true
          end,
        },
        words = {
          enabled = true,
        },
      })

      local original_delete_augroup = vim.api.nvim_del_augroup_by_id
      local safe_delete_augroup = function(group_id)
        if group_id and group_id > 0 then
          local ok, err = pcall(original_delete_augroup, group_id)
          if ok then
            return true
          end
          if err and err:find("No such group") then
            return true
          end
          return false
        end
        return true
      end

      vim.api.nvim_del_augroup_by_id = function(group_id)
        return safe_delete_augroup(group_id) or original_delete_augroup(group_id)
      end
    end,
    keys = {
      {
        "<leader>t",
        function()
          Snacks.terminal.toggle()
        end,
        desc = "Toggle terminal",
      },
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Files",
      },
      {
        "<leader>fF",
        function()
          Snacks.picker.files({
            dirs = {
              "~/github",
            },
          })
        end,
        desc = "Files (accross all projects)",
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
    },
  },
}
