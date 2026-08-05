return {
  {
    "folke/lazydev.nvim",
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
