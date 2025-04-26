-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/rmagatti/auto-session/refs/heads/main/doc/auto-session.txt"
local M = {}

M.plugins = {
  {
    "rmagatti/auto-session",
    lazy = false,
    config = function()
      local auto_session = require("auto-session")
      auto_session.setup({
        args_allow_single_directory = true,
        auto_restore = true,
        auto_restore_last_session = false,
        auto_save = true,
        bypass_save_filetypes = { "NvimTree", "neo-tree", "dashboard", "alpha", "netrw" },
        close_unsupported_windows = true,
        continue_restore_on_error = true,
        cwd_change_handling = true,
        enabled = true,
        git_use_branch_name = true,
        log_level = "error",
        session_lens = {
          load_on_setup = true,
          mappings = {
            alternate_session = { "i", "<C-s>" },
            copy_session = { "i", "<C-y>" },
            delete_session = { "i", "<C-d>" }
          },
          previewer = false,
          theme_conf = {
            border = true
          }
        },
        suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
        -- Hooks
        pre_save_cmds = {
          function()
            -- Close any floating windows before saving session
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local config = vim.api.nvim_win_get_config(win)
              if config.relative ~= "" then
                vim.api.nvim_win_close(win, false)
              end
            end
            
            -- If neovim-tree is installed, close it before saving
            local tree_ok, api = pcall(require, "nvim-tree.api")
            if tree_ok then
              api.tree.close()
            end
          end,
        },
        post_restore_cmds = {
          function()
            -- Reopen nvim-tree after session is restored if installed
            local tree_ok, api = pcall(require, "nvim-tree.api")
            if tree_ok and vim.g.nvim_tree_auto_open_on_session_restore then
              api.tree.open()
            end
            
            -- Refresh lualine after session restore
            local status_ok, lualine = pcall(require, "lualine")
            if status_ok then
              lualine.refresh()
            end
          end,
        },
      })
      vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
    end
  }
}

return M
