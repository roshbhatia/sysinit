local M = {}

M.plugins = {
  {
    "oribarilan/lensline.nvim",
    branch = "release/1.0",
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
