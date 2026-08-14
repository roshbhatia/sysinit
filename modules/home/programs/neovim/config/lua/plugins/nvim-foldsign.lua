return {
  {
    "yaocccc/nvim-foldsign",
    event = "VeryLazy",
    config = function()
      require("nvim-foldsign").setup({
        offset = -3,
        foldsigns = {
          open = "*",
          close = "-",
          seps = { "│", "┃" },
        },
        enabled = true,
      })
    end,
  },
}
