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
        auto_save_enabled = true,
        auto_restore_enabled = false, -- Disable auto restore by default
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
      
      local wk = require("which-key")
      wk.add({
        { "<leader>s", group = "Session", icon = { icon = "󱂬", hl = "WhichKeyIconCyan" } },
        { "<leader>ss", "<cmd>SessionSave<CR>", desc = "Save Session", mode = "n" },
        { "<leader>sl", "<cmd>SessionRestore<CR>", desc = "Load Session", mode = "n" },
        { "<leader>sd", "<cmd>SessionDelete<CR>", desc = "Delete Session", mode = "n" },
        { "<leader>sp", "<cmd>SessionPurgeOrphaned<CR>", desc = "Purge Orphaned Sessions", mode = "n" },
      })
      
      vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
      
      -- Auto open Alpha when Neovim starts with no arguments
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          -- Only show Alpha when:
          -- 1. No arguments were passed to nvim
          -- 2. The buffer is empty
          -- 3. It's not a directory
          local argc = vim.fn.argc()
          local bufnr = vim.api.nvim_get_current_buf()
          local bufname = vim.api.nvim_buf_get_name(bufnr)
          local buftype = vim.bo[bufnr].ft
          
          if argc == 0 and bufname == "" and buftype ~= "directory" then
            -- Check if Alpha is available before trying to open it
            local alpha_ok, _ = pcall(require, "alpha")
            if alpha_ok then
              -- Close auto-session windows if they were opened
              vim.cmd("silent! %bd")
              -- Open Alpha
              vim.cmd("Alpha")
            end
          end
        end,
        nested = true,
      })
    end
  }
}

return M