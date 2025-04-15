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
    end
  }
}

function M.setup()
  -- Register with which-key if available
  local status, wk = pcall(require, "which-key")
  if status then
    wk.register({
      ["<leader>m"] = {
        name = "🗺️ Minimap",
        ["m"] = { "<cmd>Neominimap toggle<CR>", "Toggle Minimap" },
        ["o"] = { "<cmd>Neominimap on<CR>", "Enable Minimap" },
        ["c"] = { "<cmd>Neominimap off<CR>", "Disable Minimap" },
        ["r"] = { "<cmd>Neominimap refresh<CR>", "Refresh Minimap" },
        ["f"] = { "<cmd>Neominimap focus<CR>", "Focus Minimap" },
        ["u"] = { "<cmd>Neominimap unfocus<CR>", "Unfocus Minimap" },
        ["s"] = { "<cmd>Neominimap toggleFocus<CR>", "Switch Minimap Focus" },
        
        -- Window specific controls
        ["w"] = {
          name = "Window",
          ["t"] = { "<cmd>Neominimap winToggle<CR>", "Toggle for Current Window" },
          ["r"] = { "<cmd>Neominimap winRefresh<CR>", "Refresh for Current Window" },
          ["o"] = { "<cmd>Neominimap winOn<CR>", "Enable for Current Window" },
          ["c"] = { "<cmd>Neominimap winOff<CR>", "Disable for Current Window" },
        },
        
        -- Buffer specific controls
        ["b"] = {
          name = "Buffer",
          ["t"] = { "<cmd>Neominimap bufToggle<CR>", "Toggle for Current Buffer" },
          ["r"] = { "<cmd>Neominimap bufRefresh<CR>", "Refresh for Current Buffer" },
          ["o"] = { "<cmd>Neominimap bufOn<CR>", "Enable for Current Buffer" },
          ["c"] = { "<cmd>Neominimap bufOff<CR>", "Disable for Current Buffer" },
        },
        
        -- Tab specific controls
        ["t"] = {
          name = "Tab",
          ["t"] = { "<cmd>Neominimap tabToggle<CR>", "Toggle for Current Tab" },
          ["r"] = { "<cmd>Neominimap tabRefresh<CR>", "Refresh for Current Tab" },
          ["o"] = { "<cmd>Neominimap tabOn<CR>", "Enable for Current Tab" },
          ["c"] = { "<cmd>Neominimap tabOff<CR>", "Disable for Current Tab" },
        },
      },
    })
  end
  
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
  
  -- Set recommended options for the minimap
  vim.opt.wrap = false
  vim.opt.sidescrolloff = 36 -- Set a large value for better scrolling
end

return M
