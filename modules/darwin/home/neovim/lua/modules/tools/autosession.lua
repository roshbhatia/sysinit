-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/rmagatti/auto-session/refs/heads/main/doc/auto-session.txt"
local M = {}

M.plugins = {
  {
    "rmagatti/auto-session",
    lazy = false,
    config = function()
      local auto_session = require("auto-session")
      
      auto_session.setup({
        -- Main settings
        log_level = "error",
        auto_session_enable_last_session = false,
        auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/",
        auto_session_enabled = true,
        auto_save_enabled = not vim.v.headless, -- Disable auto save in headless
        auto_restore_enabled = not vim.v.headless, -- Disable auto restore in headless
        -- Continue restoring even if errors occur (prevent disabling auto save)
        continue_restore_on_error = true,
        auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
        
        -- Session handling behavior
        auto_session_use_git_branch = true,
        auto_restore_last_session = false,
        bypass_save_filetypes = { "NvimTree", "neo-tree", "dashboard", "alpha", "netrw" },
        close_unsupported_windows = true,
        args_allow_single_directory = true,
        
        -- Additional features
        cwd_change_handling = {
          enabled = true,
          restore_upcoming_session = true,
          pre_cwd_changed_hook = nil,
          post_cwd_changed_hook = function()
            -- Refresh lualine after cwd changes
            local status_ok, lualine = pcall(require, "lualine")
            if status_ok then
              lualine.refresh()
            end
          end,
        },
        
        -- SessionLens (Telescope) integration
        session_lens = {
          load_on_setup = true,
          theme_conf = { border = true },
          previewer = false,
          mappings = {
            delete_session = { "i", "<C-d>" },
            alternate_session = { "i", "<C-s>" },
            copy_session = { "i", "<C-y>" },
          },
        },
        
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
