return {
  {
    "yaocccc/nvim-foldsign",
    event = "BufReadPost",
    config = function()
      require("nvim-foldsign").setup({
        require("nvim-foldsign").setup({
          offset = -2,
          foldsigns = {
            open = "*", -- mark the beginning of a fold
            close = "-", -- show a closed fold
            seps = { "│", "┃" }, -- open fold middle marker
          },
          enabled = true,
        }),
      })
    end,
  },
}
