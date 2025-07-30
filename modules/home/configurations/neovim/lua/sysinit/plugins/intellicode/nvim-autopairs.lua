local M = {}

M.plugins = {
  {
    "windwp/nvim-autopairs",
    deppendencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    lazy = false, -- Init seemingly taking a long time?
    config = true,
    opts = {
      check_ts = true,
    },
  },
}

return M
