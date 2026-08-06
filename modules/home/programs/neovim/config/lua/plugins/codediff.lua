return {
  {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    config = function()
      require("codediff").setup({
        explorer = {
          -- Left, not bottom. view_mode was already "tree", but a 15-line
          -- horizontal strip renders a tree as something indistinguishable from a
          -- flat list: the indent markers have nowhere to go. A vertical panel is
          -- the shape a tree needs. `i` toggles back to list at runtime.
          position = "left",
          width = 40,
          view_mode = "tree",
        },
        keymaps = {
          view = {
            toggle_explorer = "<leader>dt",
          },
          conflict = {
            -- `di`, not `dt`: `dt` is toggle_explorer above. codediff scopes the two
            -- keymap groups to different buffers so nothing broke, but one mnemonic
            -- meaning both "toggle explorer" and "accept incoming" is a trap.
            -- `di`/`dc`/`db`/`dx` now read as incoming/current/both/discard.
            accept_incoming = "<leader>di",
            accept_current = "<leader>dc",
            accept_both = "<leader>db",
            discard = "<leader>dx",
          },
        },
        diff = {
          compute_moves = true,
        },
      })

      local function clear_foldsign(buf)
        local ns = vim.api.nvim_get_namespaces()["nvim-foldsign"]
        if ns then
          vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        end
      end

      -- Apply number/fold opts to just the two diff windows.
      -- Must run via vim.schedule so it lands after welcome_window.sync restores
      -- its saved profiles (which would otherwise override these settings).
      local function apply_diff_winopts(tabpage)
        local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
        if not ok then
          return
        end
        local orig_win, mod_win = lifecycle.get_windows(tabpage)
        for _, win in ipairs({ orig_win, mod_win }) do
          if win and vim.api.nvim_win_is_valid(win) then
            vim.wo[win].number = true
            vim.wo[win].relativenumber = false
            vim.wo[win].foldenable = false
            vim.wo[win].foldcolumn = "0"
            vim.wo[win].signcolumn = "no"
            clear_foldsign(vim.api.nvim_win_get_buf(win))
          end
        end
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeDiffOpen",
        callback = function(ev)
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            vim.wo[win].foldcolumn = "0"
            vim.wo[win].signcolumn = "no"
            clear_foldsign(vim.api.nvim_win_get_buf(win))
          end
          vim.g.codediff_saved_showtabline = vim.o.showtabline
          vim.o.showtabline = 0
          require("nvim-foldsign").setup({ enabled = false })
          local tabpage = (ev.data or {}).tabpage or vim.api.nvim_get_current_tabpage()
          vim.schedule(function()
            apply_diff_winopts(tabpage)
            -- Agent review notes, written by the `diffnote` CLI. Watching starts
            -- here so a note written while the view is open still appears.
            -- pcall: this runs inside vim.schedule, where a raise becomes a
            -- traceback over the diff the reviewer is reading.
            pcall(function()
              local diffnote = require("harness.diffnote")
              diffnote.start()
              diffnote.refresh(tabpage)
            end)
          end)
        end,
      })

      -- Re-apply on every file selection: welcome_window.sync restores saved
      -- profiles synchronously, so we schedule to run after it.
      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeDiffFileSelect",
        callback = function(ev)
          local tabpage = (ev.data or {}).tabpage
          if not tabpage then
            return
          end
          vim.schedule(function()
            apply_diff_winopts(tabpage)
            pcall(function()
              require("harness.diffnote").refresh(tabpage)
            end)
          end)
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeDiffClose",
        callback = function()
          if vim.g.codediff_saved_showtabline then
            vim.o.showtabline = vim.g.codediff_saved_showtabline
            vim.g.codediff_saved_showtabline = nil
          end
          require("nvim-foldsign").setup({ enabled = true })
          pcall(function()
            require("harness.diffnote").stop()
          end)
        end,
      })
    end,
    keys = {
      {
        "<leader>dd",
        "<Cmd>CodeDiff<CR>",
        desc = "Open repo diff",
      },
      {
        "<leader>dH",
        "<Cmd>CodeDiff history<CR>",
        desc = "Open repo history",
      },
      {
        "<leader>dn",
        function()
          require("harness.diffnote").qflist()
        end,
        desc = "Agent notes to quickfix",
      },
      {
        "<leader>dN",
        function()
          require("harness.diffnote").show_at_cursor()
        end,
        desc = "Agent note under cursor",
      },
      {
        "<leader>dh",
        function()
          local filepath = vim.fn.expand("%")
          vim.cmd("CodeDiff history " .. filepath)
        end,
        desc = "Current file history",
      },
    },
  },
}
