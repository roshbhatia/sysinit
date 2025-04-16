-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/LmanTW/themify.nvim/refs/heads/main/documents/api.md"

local M = {}

M.plugins = {
  {
    "LmanTW/themify.nvim",
    lazy = false,
    priority = 999,
    config = function()
      -- Set up the themify plugin with our themes
      require("themify").setup({
        async = true, -- Enable async loading for faster startup
        activity = true, -- Track colorscheme usage activity
        "EdenEast/nightfox.nvim",
        "RRethy/base16-nvim",
        "folke/tokyonight.nvim",
        "catppuccin/nvim",
        "Shatur/neovim-ayu",
        "rmehri01/onenord.nvim",
        "rebelot/kanagawa.nvim",
        "sainnhe/sonokai",
        "sainnhe/edge",
        "sainnhe/everforest",
        "marko-cerovac/material.nvim",
        "navarasu/onedark.nvim",
        "tiagovla/tokyodark.nvim",
        "projekt0n/github-nvim-theme",
        "rose-pine/neovim",
        "nyoom-engineering/oxocarbon.nvim",
        "folke/twilight.nvim",
        "LunarVim/horizon.nvim",
        "bluz71/vim-nightfly-colors",
        "olimorris/onedarkpro.nvim",
        "rafamadriz/neon",
        "dracula/vim",
        
        -- Set default theme to one of the installed themes
        loader = function()
          -- First attempt to load whatever was used last
          local success = pcall(function()
            -- Load the last used theme if available
            require("themify").load_saved()
          end)
        end
      })
    end
  }
}

function M.setup()
  -- Register with which-key if available
  local status, wk = pcall(require, "which-key")
  if status then
    wk.register({
      ["<leader>t"] = {
        name = "🎨 Theme",
        ["t"] = { "<cmd>Themify<CR>", "Open Theme Switcher" },
        ["r"] = { "<cmd>ThemifyReload<CR>", "Reload Themes" },
        ["i"] = { "<cmd>ThemifyInstall<CR>", "Install Missing Themes" },
      },
    })
  end
  
  -- Create autocommand to ensure theme works well with transparent backgrounds
  vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
      -- Check if transparent backgrounds are enabled
      local transparent_bg = vim.g.transparent_background
      
      if transparent_bg then
        -- Make backgrounds transparent
        vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE" })
      end
    end
  })
  
  -- Initialize the transparency setting (off by default)
  vim.g.transparent_background = false
  
  -- Add a command to toggle transparency
  vim.api.nvim_create_user_command("ToggleTransparency", function()
    vim.g.transparent_background = not vim.g.transparent_background
    -- Trigger the ColorScheme event to apply changes
    vim.cmd("colorscheme " .. vim.g.colors_name)
  end, {})
  
  -- Add toggle transparency to which-key
  if status then
    wk.register({
      ["<leader>tb"] = { "<cmd>ToggleTransparency<CR>", "Toggle Transparent Background" },
    })
  end
end

return M
