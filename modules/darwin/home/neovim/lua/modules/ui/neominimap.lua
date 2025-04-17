-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/Isrothy/neominimap.nvim/refs/heads/main/doc/neominimap.nvim.txt"
local M = {}

M.plugins = {
  {
    "Isrothy/neominimap.nvim",
    version = "v3.x.x",
    event = "BufReadPost",
    config = function()
      -- Setup neominimap
      local neominimap = require("neominimap")
      
      -- Configuration
      ---@type Neominimap.UserConfig
      local config = {
        -- Enable the plugin by default
        auto_enable = true,
        
        -- Log level
        log_level = vim.log.levels.OFF,
        
        -- Notification level
        notification_level = vim.log.levels.INFO,
        
        -- Exclude certain filetypes
        exclude_filetypes = {
          "help",
          "bigfile",
          "NvimTree",
          "neo-tree",
          "lazy",
          "mason",
          "oil",
          "alpha",
          "dashboard",
          "TelescopePrompt",
          "toggleterm",
        },
        
        -- Exclude certain buftypes
        exclude_buftypes = {
          "nofile",
          "nowrite",
          "quickfix",
          "terminal",
          "prompt",
        },
        
        -- Size and layout settings
        x_multiplier = 4,
        y_multiplier = 1,
        layout = "float", -- "float" or "split"
        
        -- Split window settings (when layout = "split")
        split = {
          minimap_width = 20,
          fix_width = true,
          direction = "right",
          close_if_last_window = true,
        },
        
        -- Float window settings (when layout = "float")
        float = {
          minimap_width = 20,
          max_minimap_height = nil,
          margin = {
            right = 0,
            top = 0,
            bottom = 0,
          },
          z_index = 10,
          window_border = "single",
        },
        
        -- Performance settings
        delay = 200,
        
        -- Cursor and interaction settings
        sync_cursor = true,
        click = {
          enabled = true,
          auto_switch_focus = false,
        },
        
        -- Feature integration
        diagnostic = {
          enabled = true,
          severity = vim.diagnostic.severity.WARN,
          mode = "line",
        },
        
        git = {
          enabled = true,
          mode = "sign",
        },
        
        treesitter = {
          enabled = true,
        },
        
        search = {
          enabled = true,
          mode = "line",
        },
        
        mark = {
          enabled = true,
          mode = "icon",
          show_builtins = false,
        },
        
        fold = {
          enabled = true,
        },
        
        -- Custom window options
        winopt = function(opt, winid)
          -- Add any custom window options here
          opt.winblend = 10 -- Semi-transparent minimap
        end,
        
        -- Custom buffer options
        bufopt = function(opt, bufnr)
          -- Add any custom buffer options here
        end,
      }
      
      vim.g.neominimap = config
      
      -- Initialize lualine integration if lualine is available
      local has_lualine, _ = pcall(require, "lualine")
      if has_lualine then
        local minimap_extension = require("neominimap.statusline").lualine_default
        require('lualine').setup({
          extensions = vim.list_extend(
            require('lualine').extensions or {},
            { minimap_extension }
          )
        })
      end
      
      -- Register with which-key
      local wk = require("which-key")
      wk.add({
        { "<leader>m", group = "Minimap", icon = { icon = "🗺️", hl = "WhichKeyIconBlue" } },
        { "<leader>mm", "<cmd>Neominimap toggle<CR>", desc = "Toggle Minimap", mode = "n" },
        { "<leader>mo", "<cmd>Neominimap on<CR>", desc = "Enable Minimap", mode = "n" },
        { "<leader>mc", "<cmd>Neominimap off<CR>", desc = "Disable Minimap", mode = "n" },
        { "<leader>mr", "<cmd>Neominimap refresh<CR>", desc = "Refresh Minimap", mode = "n" },
        { "<leader>mf", "<cmd>Neominimap focus<CR>", desc = "Focus Minimap", mode = "n" },
        { "<leader>mu", "<cmd>Neominimap unfocus<CR>", desc = "Unfocus Minimap", mode = "n" },
        { "<leader>ms", "<cmd>Neominimap toggleFocus<CR>", desc = "Switch Minimap Focus", mode = "n" },
        
        -- Window specific controls
        { "<leader>mw", group = "Window Controls", mode = "n" },
        { "<leader>mwt", "<cmd>Neominimap winToggle<CR>", desc = "Toggle for Current Window", mode = "n" },
        { "<leader>mwr", "<cmd>Neominimap winRefresh<CR>", desc = "Refresh for Current Window", mode = "n" },
        { "<leader>mwo", "<cmd>Neominimap winOn<CR>", desc = "Enable for Current Window", mode = "n" },
        { "<leader>mwc", "<cmd>Neominimap winOff<CR>", desc = "Disable for Current Window", mode = "n" },
        
        -- Buffer specific controls
        { "<leader>mb", group = "Buffer Controls", mode = "n" },
        { "<leader>mbt", "<cmd>Neominimap bufToggle<CR>", desc = "Toggle for Current Buffer", mode = "n" },
        { "<leader>mbr", "<cmd>Neominimap bufRefresh<CR>", desc = "Refresh for Current Buffer", mode = "n" },
        { "<leader>mbo", "<cmd>Neominimap bufOn<CR>", desc = "Enable for Current Buffer", mode = "n" },
        { "<leader>mbc", "<cmd>Neominimap bufOff<CR>", desc = "Disable for Current Buffer", mode = "n" },
      })
      
      -- Set up highlight groups for better integration with your colorscheme
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          -- Basic minimap highlights
          vim.api.nvim_set_hl(0, "NeominimapBackground", { link = "Normal" })
          vim.api.nvim_set_hl(0, "NeominimapBorder", { link = "FloatBorder" })
          vim.api.nvim_set_hl(0, "NeominimapCursorLine", { link = "CursorLine" })
          
          -- Diagnostic highlights
          vim.api.nvim_set_hl(0, "NeominimapErrorLine", { link = "DiagnosticVirtualTextError" })
          vim.api.nvim_set_hl(0, "NeominimapWarnLine", { link = "DiagnosticVirtualTextWarn" })
          vim.api.nvim_set_hl(0, "NeominimapInfoLine", { link = "DiagnosticVirtualTextInfo" })
          vim.api.nvim_set_hl(0, "NeominimapHintLine", { link = "DiagnosticVirtualTextHint" })
          
          -- Git highlights
          vim.api.nvim_set_hl(0, "NeominimapGitAddLine", { link = "DiffAdd" })
          vim.api.nvim_set_hl(0, "NeominimapGitChangeLine", { link = "DiffChange" })
          vim.api.nvim_set_hl(0, "NeominimapGitDeleteLine", { link = "DiffDelete" })
          
          -- Search highlights
          vim.api.nvim_set_hl(0, "NeominimapSearchLine", { link = "Search" })
        end,
      })
    end
  }
}

return M