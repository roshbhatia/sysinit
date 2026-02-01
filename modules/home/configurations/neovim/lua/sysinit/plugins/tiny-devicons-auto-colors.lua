return {
  {
    "rachartier/tiny-devicons-auto-colors.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    event = "VeryLazy",
    config = function()
      -- When Nix-managed, colors come from stylix
      -- When not Nix-managed, use default colors from the colorscheme
      require("tiny-devicons-auto-colors").setup()
    end,
  },
}
