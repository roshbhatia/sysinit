return {
  {
    "nmac427/guess-indent.nvim",
    event = "InsertEnter",
    config = function()
      require("guess-indent").setup({})
    end,
  },
}
