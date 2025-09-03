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
        {
          name = "last_author",
          enabled = true,
        },
        {
          name = "diagnostics",
          enabled = true,
          min_level = "INFO", -- only show WARN and ERROR by default (HINT, INFO, WARN, ERROR)
        },
        {
          name = "complexity",
          enabled = false, -- disabled by default - enable explicitly to use
          min_level = "L", -- only show L (Large) and XL (Extra Large) complexity by default
        },
      })
    end,
  },
}

return M
