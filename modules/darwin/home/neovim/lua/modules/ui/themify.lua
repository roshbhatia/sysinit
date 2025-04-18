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
  local wk = require("which-key")
  wk.add({
    { "<leader>t", group = "🎨 Theme", icon = { icon = "🎨" } },
    { "<leader>tt", "<cmd>Themify<CR>", desc = "Open Theme Switcher" },
    { "<leader>tr", "<cmd>ThemifyReload<CR>", desc = "Reload Themes" },
    { "<leader>ti", "<cmd>ThemifyInstall<CR>", desc = "Install Missing Themes" },
  })
end

return M
