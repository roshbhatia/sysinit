local M = {}

M.plugins = {
  {
    "folke/trouble.nvim",
    event = "LSPAttach",
    opts = {
      auto_preview = false,
      open_no_results = true,
      use_diagnostic_signs = true,
      preview = {
        type = "float",
      },
    },
    keys = function()
      return {
        {
          "<leader>cx",
          "<CMD>Trouble diagnostics toggle<CR>",
          desc = "Project diagnostics",
        },
      }
    end,
  },
}

return M
