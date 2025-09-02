---@diagnostic disable: missing-parameter
local M = {}

M.plugins = {
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    event = "VeryLazy",
    config = function()
      require("nvim-dap-virtual-text").setup({})
    end,
  },
}

return M
