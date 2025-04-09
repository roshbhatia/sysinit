return {
  {
    "zaldih/themery.nvim",
    lazy = false,
    config = function()
      require("themery").setup({
        themes = {
          { name = "Gruvbox Dark", colorscheme = "gruvbox", before = [[vim.opt.background = "dark"]] },
          { name = "Gruvbox Light", colorscheme = "gruvbox", before = [[vim.opt.background = "light"]] },
          { name = "Kanagawa Lotus", colorscheme = "kanagawa-lotus" },
          { name = "Kanagawa Dragon", colorscheme = "kanagawa-dragon" },
          { name = "Catppuccin Mocha", colorscheme = "catppuccin-mocha" },
          { name = "Catppuccin Latte", colorscheme = "catppuccin-latte" },
          { name = "Tokyonight Storm", colorscheme = "tokyonight-storm" },
          { name = "Tokyonight Night", colorscheme = "tokyonight-night" },
          { name = "Carbonfox", colorscheme = "carbonfox" },
          { name = "Nightfox", colorscheme = "nightfox" },
          { name = "Nord", colorscheme = "nord" },
          { name = "Onedark", colorscheme = "onedark" },
          { name = "Onenord", colorscheme = "onenord" },
          { name = "Darkplus", colorscheme = "darkplus" },
          { name = "Dracula", colorscheme = "dracula" },
          { name = "GitHub Dark", colorscheme = "github_dark" },
          { name = "GitHub Light", colorscheme = "github_light" },
          { name = "Ayu Dark", colorscheme = "ayu-dark" },
          { name = "Ayu Light", colorscheme = "ayu-light" },
          { name = "Solarized Dark", colorscheme = "solarized" },
          { name = "Base16 Vibrant", colorscheme = "base16-vibrant" },
          { name = "Base16 Dark", colorscheme = "base16-dark" },
          { name = "Agnoster", colorscheme = "agnoster" },
        },
        livePreview = true, -- Apply theme while picking
      })

      -- Keybinding for theme switching
      vim.keymap.set("n", "<leader>9", "<cmd>Themery<CR>", { desc = "Switch Theme" })
    end,
  },
  -- Add all required themes
  { "gruvbox-community/gruvbox" },
  { "rebelot/kanagawa.nvim" },
  { "catppuccin/nvim", name = "catppuccin" },
  { "folke/tokyonight.nvim" },
  { "EdenEast/nightfox.nvim" },
  { "shaunsingh/nord.nvim" },
  { "navarasu/onedark.nvim" },
  { "rmehri01/onenord.nvim" },
  { "lunarvim/darkplus.nvim" },
  { "Mofiqul/dracula.nvim" },
  { "projekt0n/github-nvim-theme" },
  { "Shatur/neovim-ayu" },
  { "ishan9299/nvim-solarized-lua" },
  { "RRethy/nvim-base16" },
}
