local M = {}

M.plugins = {
  {
    "igorlfs/nvim-dap-view",
    event = "VeryLazy",
    opts = {},
    keys = function()
      return {
        {
          "<leader>dd",
          function()
            vim.cmd("DapViewToggle")
          end,
          desc = "Toggle dap view",
        },
      }
    end,
  },
}

return M
