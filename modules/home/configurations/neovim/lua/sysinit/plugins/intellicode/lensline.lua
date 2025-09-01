local M = {}

M.plugins = {
  {
    "oribarilan/lensline.nvim",
    branch = "main",
    event = "LspAttach",
    config = function()
      require("lensline").setup({
        {
          name = "references",
          enabled = false,
        },
      })
    end,
  },
}

return M
