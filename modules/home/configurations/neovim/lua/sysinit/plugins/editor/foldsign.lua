local M = {}

M.plugins = {
  {
    "yaocccc/nvim-foldsign",
    config = function()
      local foldsign = require("nvim-foldsign")
      foldsign.setup({
        offset = -3,
        foldsigns = {
          open = "*",
          close = "-",
          seps = { "│", "┃" },
        },
        enabled = true,
      })

      local original_foldsign = foldsign.foldsign
      foldsign.foldsign = function()
        local win = vim.api.nvim_get_current_win()
        local cfg = vim.api.nvim_win_get_config(win)
        if cfg.relative ~= "" then
          vim.api.nvim_buf_clear_namespace(0, foldsign.ns, 0, -1)
          return
        end
        original_foldsign()
      end
    end,
  },
}

return M

