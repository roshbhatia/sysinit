-- Configure smooth scrolling behavior
local M = {}

M.setup = function()
  -- Enable mouse support with all modes (a = all)
  vim.opt.mouse = "a"

  -- Set scrolloff to keep cursor from hitting the edges
  vim.opt.scrolloff = 8
  vim.opt.sidescrolloff = 8

  -- Configure scroll settings for smoother experience
  vim.opt.scrolljump = 5
  vim.opt.mousescroll = "ver:3,hor:6"  -- Smoother mouse scrolling

  -- Add smooth scrolling behavior
  vim.keymap.set({"n", "v"}, "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
  vim.keymap.set({"n", "v"}, "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
  vim.keymap.set({"n", "v"}, "<C-f>", "<C-f>zz", { desc = "Page down and center" })
  vim.keymap.set({"n", "v"}, "<C-b>", "<C-b>zz", { desc = "Page up and center" })

  -- Add padding for smoother scrolling feels
  vim.opt.smoothscroll = true   -- Smooth scrolling for half-page jumps
  
  -- Enable if using Neovim >= 0.10
  if vim.fn.has('nvim-0.10') == 1 then
    vim.opt.mousemoveevent = true  -- Enable mouse move events
  end

  print("Smooth scrolling configured")
end

return M
