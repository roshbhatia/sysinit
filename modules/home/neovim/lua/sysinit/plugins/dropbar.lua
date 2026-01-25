return {
  {
    "Bekaboo/dropbar.nvim",
    branch = "master",
    lazy = false,
    config = function()
      require("dropbar").setup({
        icons = {
          ui = {
            bar = {
              separator = "  ",
              extends = "…",
            },
          },
        },
        menu = {
          scrollbar = {
            enable = false,
          },
        },
      })
    end,
  },
}
