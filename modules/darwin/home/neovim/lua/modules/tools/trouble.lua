-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/folke/trouble.nvim/refs/heads/main/docs/examples.md"
-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/folke/trouble.nvim/refs/heads/main/README.md"
local M = {}

M.plugins = {
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("trouble").setup({
        icons = true,
        fold_open = "",
        fold_closed = "",
        signs = {
          error = "E",
          warning = "W",
          hint = "H",
          information = "I",
          other = "O",
        },
        use_diagnostic_signs = true,
      })
    end,
  },
}

return M
