local M = {}

M.plugins = {
  {
    "Isrothy/neominimap.nvim",
    version = "v3.x.x",
    cmds = {
      "Neominimap",
    },
    init = function()
      vim.opt_local.wrap = false
      vim.opt_local.sidescrolloff = 36
      vim.g.neominimap = {
        auto_enable = false,
      }
    end,
    keys = function()
      return {
        {
          "<leader>em",
          function() vim.cmd("Neominimap Toggle") end,
          desc = "Toggle minimap",
        },
      }
    end,
  },
}

return M
