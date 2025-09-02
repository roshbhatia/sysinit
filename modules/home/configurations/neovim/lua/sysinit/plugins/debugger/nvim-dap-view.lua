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
            vim.cmd("DapViewOpen")
          end,
          desc = "UI",
        },
      }
    end,
  },
}

return M
