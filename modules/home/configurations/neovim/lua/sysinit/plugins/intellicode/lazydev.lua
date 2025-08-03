local M = {}

M.plugins = {
  {
    "folke/lazydev.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
    },
    ft = "lua",
    opts = {
      library = {
        {
          path = "wezterm-types",
          mods = {
            "wezterm",
          },
        },
        {
          path = "${3rd}/luv/library",
          words = {
            "vim%.uv",
          },
        },
      },
    },
  },
}

return M
