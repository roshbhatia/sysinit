-- Safely load nvim-tree
local status_ok_icons, icons = pcall(require, 'nvim-web-devicons')
if status_ok_icons then
  icons.setup()
end

local status_ok_tree, nvim_tree = pcall(require, 'nvim-tree')
if status_ok_tree then
  nvim_tree.setup()
end
