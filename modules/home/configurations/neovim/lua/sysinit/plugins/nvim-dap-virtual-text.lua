return {
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    lazy = true,
    config = function()
      require("nvim-dap-virtual-text").setup()
    end,
  },
}
