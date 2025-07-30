local M = {}

M.plugins = {
  {
    "folke/lazydev.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
    },
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- Load the wezterm types when the `wezterm` module is required
        -- Needs `justinsgithub/wezterm-types` to be installed
        {
          path = "wezterm-types",
          mods = {
            "wezterm",
          },
        },
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
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
