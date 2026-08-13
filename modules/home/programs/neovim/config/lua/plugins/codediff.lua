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

      local function clear_foldsign(buf)
        local ns = vim.api.nvim_get_namespaces()["nvim-foldsign"]
        if ns then
          vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
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
          require("nvim-foldsign").setup({ enabled = true })
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
