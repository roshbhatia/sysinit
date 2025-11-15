local M = {}

M.plugins = {
  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    event = "LSPAttach",
    config = function()
      require("sysinit.plugins.intellicode.lsp_lines_wrapper").setup()
    end,
  },
}

return M
