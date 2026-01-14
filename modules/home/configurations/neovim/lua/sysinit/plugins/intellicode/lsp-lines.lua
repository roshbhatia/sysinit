local M = {}

M.plugins = {
  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    event = "LSPAttach",
    config = function()
      require("sysinit.utils.lsp_lines_wrapper").setup()
    end,
  },
}

return M
