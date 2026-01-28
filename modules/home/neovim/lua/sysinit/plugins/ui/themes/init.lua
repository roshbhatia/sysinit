-- Pixel.nvim: Dynamic colorscheme that adapts to terminal ANSI colors
-- This allows all terminal theme colors to automatically flow into Neovim

local function setup_pixel()
  -- Disable GUI colors to use terminal ANSI colors
  vim.opt.termguicolors = false

  -- Configure pixel.nvim
  require("pixel").setup({
    disable_italics = false,
  })

  -- Apply the colorscheme
  vim.cmd.colorscheme("pixel")
end

return {
  {
    "bjarneo/pixel.nvim",
    lazy = false,
    priority = 1000,
    config = setup_pixel,
  },
}
