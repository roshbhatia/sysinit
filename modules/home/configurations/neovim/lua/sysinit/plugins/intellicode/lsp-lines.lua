return {
  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    event = "LSPAttach",
    config = function()
      local lsp_lines = require("lsp_lines")
      local original_hide = lsp_lines.hide
      local original_show = lsp_lines.show

      lsp_lines.hide = function()
        local ok, err = pcall(original_hide)
        if not ok and err and err:match("Invalid buffer id") then
          vim.notify("LSP Lines: Buffer no longer exists", vim.log.levels.WARN)
        elseif not ok then
          vim.notify("LSP Lines error: " .. tostring(err), vim.log.levels.ERROR)
        end
      end

      lsp_lines.show = function()
        local ok, err = pcall(original_show)
        if not ok and err and err:match("Invalid buffer id") then
          vim.notify("LSP Lines: Buffer no longer exists", vim.log.levels.WARN)
        elseif not ok then
          vim.notify("LSP Lines error: " .. tostring(err), vim.log.levels.ERROR)
        end
      end

      lsp_lines.setup()
    end,
  },
}
