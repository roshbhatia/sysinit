-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/folke/trouble.nvim/refs/heads/main/docs/examples.md"
-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/folke/trouble.nvim/refs/heads/main/README.md"
local M = {}

M.plugins = {
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
}

return M
