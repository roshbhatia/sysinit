return {
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    ft = { "markdown", "quarto", "rmd" },
    keys = {
      {
        "<localleader>p",
        "<cmd>Markview toggle<cr>",
        desc = "Toggle preview",
        ft = { "markdown", "quarto", "rmd" },
      },
    },
  },
}
