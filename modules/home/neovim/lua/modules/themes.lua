local M = {}

M.plugins = {
  {
    "zaldih/themery.nvim",
    lazy = false,
    opts = {
      themes = {
        { name = "Gruvbox Dark", colorscheme = "gruvbox", before = [[vim.opt.background = "dark"]] },
        { name = "Gruvbox Light", colorscheme = "gruvbox", before = [[vim.opt.background = "light"]] },
        { name = "Kanagawa Dragon", colorscheme = "kanagawa-dragon" },
        { name = "Kanagawa Wave", colorscheme = "kanagawa-wave" },
        { name = "Catppuccin Mocha", colorscheme = "catppuccin-mocha" },
        { name = "Catppuccin Latte", colorscheme = "catppuccin-latte" },
        { name = "Tokyonight Storm", colorscheme = "tokyonight-storm" },
        { name = "Tokyonight Night", colorscheme = "tokyonight-night" },
        { name = "Carbonfox", colorscheme = "carbonfox" },
        { name = "Nightfox", colorscheme = "nightfox" },
        { name = "Duskfox", colorscheme = "duskfox" },
        { name = "Nord", colorscheme = "nord" },
        { name = "Onedark", colorscheme = "onedark" },
        { name = "Onenord", colorscheme = "onenord" },
        { name = "Rose Pine", colorscheme = "rose-pine" },
        { name = "Rose Pine Moon", colorscheme = "rose-pine-moon" },
        { name = "Dracula", colorscheme = "dracula" },
        { name = "Material Deep Ocean", colorscheme = "material-deep-ocean" },
        { name = "Github Dark", colorscheme = "github_dark" },
        { name = "Oxocarbon Dark", colorscheme = "oxocarbon" },
      },
      livePreview = true,
    },
    keys = {
      { "<leader>9", "<cmd>Themery<CR>", desc = "Switch Theme" },
    },
  },
  -- Theme plugins
  { "gruvbox-community/gruvbox" },
  { "rebelot/kanagawa.nvim" },
  { "catppuccin/nvim", name = "catppuccin" },
  { "folke/tokyonight.nvim" },
  { "EdenEast/nightfox.nvim" },
  { "shaunsingh/nord.nvim" },
  { "navarasu/onedark.nvim" },
  { "rmehri01/onenord.nvim" },
  { "rose-pine/neovim", name = "rose-pine" },
  { "Mofiqul/dracula.nvim" },
  { "marko-cerovac/material.nvim" },
  { "projekt0n/github-nvim-theme" },
  { "nyoom-engineering/oxocarbon.nvim" },
}

function M.setup()
  -- Any post-plugin-load setup can go here
end

require("core").register("themes", M)

return M
