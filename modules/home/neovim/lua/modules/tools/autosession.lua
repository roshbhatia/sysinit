# sysinit.nvim.readme-url="https://raw.githubusercontent.com/rmagatti/auto-session/main/README.md"

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
        auto_restore_enabled = true,
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
    end
  }
}

function M.setup()
  -- Add which-key integration
  local status, wk = pcall(require, "which-key")
  if status then
    wk.register({
      ["<leader>s"] = {
        name = "🪟 Session",
        s = { "<cmd>SessionSave<CR>", "Save Session" },
        l = { "<cmd>SessionRestore<CR>", "Load Session" },
        d = { "<cmd>SessionDelete<CR>", "Delete Session" },
        f = { "<cmd>SessionSearch<CR>", "Find Session" },
        p = { "<cmd>SessionPurgeOrphaned<CR>", "Purge Orphaned Sessions" },
        t = { "<cmd>SessionToggleAutoSave<CR>", "Toggle Auto Save" },
        a = { "<cmd>SessionDisableAutoSave<CR>", "Disable Auto Save" },
        A = { "<cmd>SessionDisableAutoSave!<CR>", "Enable Auto Save" },
      },
    })
  end
  
  -- Set the recommended sessionoptions
  vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
  
  -- Add statusline integration function (can be called from lualine config)
  -- Example usage in lualine: require('auto-session-library').current_session_name()
  M.current_session_name = function(shorten)
    if not package.loaded['auto-session.lib'] then
      return ""
    end
    
    local session_name = require('auto-session.lib').current_session_name(shorten or false)
    if session_name and session_name ~= "" then
      return "󱂬 " .. session_name
    else
      return ""
    end
  end
end

return M
