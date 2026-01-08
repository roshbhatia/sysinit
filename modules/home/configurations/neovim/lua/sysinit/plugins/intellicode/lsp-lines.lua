local M = {}

M.plugins = {
  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    event = "LSPAttach",
    config = function()
      local lsp_lines = require("lsp_lines")
      local original_hide = lsp_lines.hide
      local original_show = lsp_lines.show

      lsp_lines.hide = function()
        pcall(original_hide)
      end

      lsp_lines.show = function()
        pcall(original_show)
      end

      lsp_lines.setup()
    end,
  },
}

return M
