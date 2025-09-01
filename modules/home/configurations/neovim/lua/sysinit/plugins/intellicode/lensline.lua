local M = {}

M.plugins = {
  {
    "oribarilan/lensline.nvim",
    branch = "release/1.x",
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
