-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/folke/which-key.nvim/refs/heads/main/doc/which-key.nvim.txt"
local M = {}

M.plugins = {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    config = function()
      local status_ok, wk = pcall(require, "which-key")
      if not status_ok then
        vim.notify("which-key not found!", vim.log.levels.ERROR)
        return
      end

      wk.setup({
        plugins = {
          marks = true,
          registers = true,
          spelling = { enabled = false },
          presets = {
            operators = true,
            motions = true,
            text_objects = true,
            windows = true,
            nav = true,
            z = true,
            g = true,
          },
        },
        window = {
          border = "rounded",
          padding = { 2, 2, 2, 2 },
        },
        layout = {
          align = "left",
          spacing = 3,
        },
        show_help = true,
        triggers = "auto",
      })
    end
  }
}

return M
