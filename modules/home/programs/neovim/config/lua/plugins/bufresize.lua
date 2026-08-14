return {
  {
    "kwkarlwang/bufresize.nvim",
    event = "VeryLazy",
    config = function()
      require("bufresize").setup()
    end,
  },
}
