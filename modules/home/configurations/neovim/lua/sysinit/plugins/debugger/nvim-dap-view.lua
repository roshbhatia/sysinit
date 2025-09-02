local M = {}

M.plugins = {
  {
    "igorlfs/nvim-dap-view",
    opts = {},
    keys = function()
      return {
        {
          "<leader>dd",
          function()
            vim.cmd("DapViewToggle")
          end,
          desc = "Toggle DAP View",
        },
      }
    end,
  },
}

return M
