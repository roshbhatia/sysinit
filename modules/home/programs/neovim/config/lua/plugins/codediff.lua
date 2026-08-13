return {
  {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    config = function()
      require("codediff").setup({
        explorer = {
          -- Left, with the changed-file list along the bottom: the file tree and the
          -- diff sit side by side, and the list under both crosses repositories the
          -- tree cannot, since codediff's tree is rooted in one repository.
          position = "left",
          view_mode = "tree",
        },
        keymaps = {
          view = {
            toggle_explorer = "<leader>dt",
            -- Off the bare letters.
            quit = "<leader>dq",
            toggle_layout = "<leader>dl",
          },
          conflict = {
            accept_incoming = "<leader>di",
            accept_current = "<leader>dc",
            accept_both = "<leader>db",
            discard = "<leader>dx",
          },
        },
        diff = {
          compute_moves = true,

          -- One pane with deletions rendered as virtual lines, which is what a reader
          -- wants for the common case of reading a change in the buffer it lands in.
          layout = "inline",
        },
      })

      -- `foldsign`, which is what the plugin registers; under its own name this cleared
      -- nothing, so an indicator drawn before the diff opened stayed. It is placed at
      -- `virt_text_win_col = -2 - numberwidth`, and nvim clamps a position the gutter
      -- cannot hold onto the text, which ate the first character of `func main() {`.
      local function clear_foldsign(buf)
        local ns = vim.api.nvim_get_namespaces()["foldsign"]
        if ns then
          vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        end
      end

      -- Every loaded buffer, not the diff windows' alone: the diff opens in a new tab, so
      -- at `CodeDiffOpen` the window holding the annotated file may not exist yet.
      local function clear_foldsign_everywhere()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            clear_foldsign(buf)
          end
        end
      end

      -- The field `foldsign()` tests, rather than `setup()`: each `setup` call appends
      -- another copy of its six autocmds to the default group, so toggling through it
      -- left one more CursorMoved handler behind per diff session.
      local function foldsign_enabled(on)
        local ok, foldsign = pcall(require, "nvim-foldsign")
        if ok then
          foldsign.enabled = on
        end
      end

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
            -- One column, not "no". A gutter of zero is what let a clamped virt_text land
            -- on the text, and the review's note sign needs somewhere to draw.
            vim.wo[win].signcolumn = "yes:1"
            clear_foldsign(vim.api.nvim_win_get_buf(win))
          end
        end
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeDiffOpen",
        callback = function(ev)
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            vim.wo[win].foldcolumn = "0"
          end
          clear_foldsign_everywhere()
          vim.g.codediff_saved_showtabline = vim.o.showtabline
          vim.o.showtabline = 0
          foldsign_enabled(false)
          local tabpage = (ev.data or {}).tabpage or vim.api.nvim_get_current_tabpage()
          vim.schedule(function()
            apply_diff_winopts(tabpage)
          end)
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeDiffFileSelect",
        callback = function(ev)
          local tabpage = (ev.data or {}).tabpage
          if not tabpage then
            return
          end
          vim.schedule(function()
            apply_diff_winopts(tabpage)
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
          foldsign_enabled(true)
        end,
      })
    end,
    keys = {
      {
        "<leader>dd",
        function()
          require("harness.api").review_workspace()
        end,
        desc = "Review the workspace diff",
      },
      {
        -- History is per repository by nature: a commit list spanning several
        -- repositories is a fiction, so this one still resolves to one.
        "<leader>dH",
        function()
          require("utils.gitrepo").resolve(function(root)
            vim.cmd("CodeDiff --repo " .. vim.fn.fnameescape(root) .. " history")
          end)
        end,
        desc = "Open repo history",
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
