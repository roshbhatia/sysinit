vim.o.loadplugins = false
vim.o.termguicolors = true
vim.o.winborder = "rounded"
vim.o.number = true
vim.g.maplocalleader = ","
-- User filetype hooks can depend on plugins omitted by the review startup.
vim.opt.runtimepath:remove(vim.fn.stdpath("config") .. "/after")
vim.cmd.syntax("enable")

local theme = vim.fn.stdpath("data") .. "/lazy/catppuccin"
if vim.uv.fs_stat(theme) then
  vim.opt.runtimepath:append(theme)
  local found, specs = pcall(require, "plugins.themes")
  if found and pcall(specs[1].config) then
    return
  end
end
vim.cmd.colorscheme("habamax")
