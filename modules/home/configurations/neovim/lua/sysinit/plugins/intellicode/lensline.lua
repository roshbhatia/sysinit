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
        {
          name = "last_author",
        },
        {
          name = "diagnostics",
          enabled = true,
          min_level = "INFO",
        },
        {
          name = "complexity",
          enabled = true,
        },
      })
    end,
  },
}

return M
