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
        gh = {
          enabled = true,
        },
      })

      local snacks_notify = Snacks.notifier.notify

      -- global dedupe state
      local _notify_state = {
        last = {}, -- key -> timestamp
      }

      local function _ts()
        return (vim.uv or vim.loop).now()
      end

      local function _dedupe_key(msg, level, title)
        return string.format("%s|%s|%s", level or "", title or "", msg)
      end

      _notify_state.intervals = {
        [vim.log.levels.ERROR] = 4000,
        [vim.log.levels.WARN] = 2500,
        [vim.log.levels.INFO] = 1500,
        default = 1000,
      }

      local function _should_emit(msg, level, title)
        local key = _dedupe_key(msg, level, title)
        local now = _ts()
        local prev = _notify_state.last[key] or 0
        local interval = _notify_state.intervals[level] or _notify_state.intervals.default
        if (now - prev) < interval then
          return false
        end
        _notify_state.last[key] = now
        return true
      end

      local function _sanitize(msg)
        if type(msg) == "table" then
          local ok, json = pcall(vim.json.encode, msg)
          if ok then
            return json
          end
          return vim.inspect(msg)
        end
        return tostring(msg)
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      vim.notify = function(msg, level, opts)
        level = level or vim.log.levels.INFO
        opts = opts or {}
        local title = opts.title or "SysInit"
        if title and string.find(string.lower(title), "fswatch") then
          return -- suppress noisy fswatch messages
        end
        msg = _sanitize(msg)
        if not _should_emit(msg, level, title) then
          return
        end
        opts.title = title
        snacks_notify(msg, level, opts)
      end

      -- route error writes
      local _orig_err_write = vim.api.nvim_err_writeln
      vim.api.nvim_err_writeln = function(msg)
        msg = _sanitize(msg)
        vim.notify(msg, vim.log.levels.ERROR, { title = "Error" })
      end

      -- helper API
      vim.sysinit_notify = {
        info = function(msg, o)
          vim.notify(msg, vim.log.levels.INFO, o)
        end,
        warn = function(msg, o)
          vim.notify(msg, vim.log.levels.WARN, o)
        end,
        error = function(msg, o)
          vim.notify(msg, vim.log.levels.ERROR, o)
        end,
        debug = function(msg, o)
          vim.notify(msg, vim.log.levels.DEBUG, o)
        end,
        raw = function(msg, level, o)
          level = level or vim.log.levels.INFO
          o = o or {}
          snacks_notify(_sanitize(msg), level, o) -- bypass dedupe intentionally
        end,
        clear = function()
          _notify_state.last = {}
          snacks_notify("Notification cache cleared", vim.log.levels.INFO, { title = "SysInit" })
        end,
        stats = function()
          local count = 0
          for _ in pairs(_notify_state.last) do
            count = count + 1
          end
          return { entries = count }
        end,
      }

      if not vim.api.nvim_get_commands({})["SysNotifyClear"] then
        vim.api.nvim_create_user_command("SysNotifyClear", function()
          vim.sysinit_notify.clear()
        end, { desc = "Clear SysInit notification dedupe cache" })
      end

      local lsp_level_map = {
        ERROR = vim.log.levels.ERROR,
        WARNING = vim.log.levels.WARN,
        INFO = vim.log.levels.INFO,
        LOG = vim.log.levels.INFO,
        DEBUG = vim.log.levels.DEBUG,
      }

      local function _lsp_notify(method, params)
        if not params or not params.message then
          return
        end
        local lsp_level = params.type and lsp_level_map[params.type] or vim.log.levels.INFO
        vim.notify(params.message, lsp_level, { title = method })
      end

      local lsp = vim.lsp
      if lsp and lsp.handlers then
        lsp.handlers["window/showMessage"] = function(err, method, params, client_id, bufnr, config)
          _lsp_notify("LSP Message", params)
        end
        lsp.handlers["window/logMessage"] = function(err, method, params, client_id, bufnr, config)
          _lsp_notify("LSP Log", params)
        end
      end

      -- optional override of vim.print for consistency (non-intrusive)
      local _orig_print = vim.print
      vim.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
          parts[#parts + 1] = _sanitize(select(i, ...))
        end
        local combined = table.concat(parts, " ")
        if _should_emit(combined, vim.log.levels.DEBUG, "Print") then
          snacks_notify(combined, vim.log.levels.DEBUG, { title = "Print" })
        end
        return ...
      end

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
