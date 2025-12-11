local M = {}

M.plugins = {
  {
    "igorlfs/nvim-dap-view",
    opts = {},
    keys = function()
      return {
        {
          "<leader>ced",
          function()
            vim.cmd("DapViewToggle")
          end,
          desc = "Toggle DAP View",
        },
      }
    end,
          desc = "Toggle DAP View",
        },
      }
    end,
  },
}

return M
