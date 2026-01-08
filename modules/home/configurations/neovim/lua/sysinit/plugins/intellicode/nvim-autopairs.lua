local M = {}

M.plugins = {
  {
    "windwp/nvim-autopairs",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    event = "InsertEnter",
    config = true,
    opts = {
      check_ts = true,
    },
  },
}

return M
