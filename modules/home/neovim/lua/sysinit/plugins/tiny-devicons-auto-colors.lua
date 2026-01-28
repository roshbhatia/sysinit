return {
  {
    "rachartier/tiny-devicons-auto-colors.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    event = "VeryLazy",
    config = function()
      -- Auto-color devicons based on current colorscheme
      -- Will automatically adapt to pixel.nvim's terminal colors
      require("tiny-devicons-auto-colors").setup()
    end,
  },
}
