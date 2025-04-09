return {
  {
    "lewis6991/impatient.nvim",
    config = function()
      require("impatient")
    end,
  },
  {
    "iamcco/markdown-preview.nvim",
    run = "cd app && yarn install",
    ft = { "markdown" },
  },
  {
    "akinsho/bufferline.nvim",
    requires = "kyazdani42/nvim-web-devicons",
    config = function()
      require("bufferline").setup{}
    end,
  },
  {
    "folke/trouble.nvim",
    requires = "kyazdani42/nvim-web-devicons",
    config = function()
      require("trouble").setup{}
    end,
  },
}
