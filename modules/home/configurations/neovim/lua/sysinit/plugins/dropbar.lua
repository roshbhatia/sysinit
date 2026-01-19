return {
  {
    "Bekaboo/dropbar.nvim",
    branch = "master",
    event = "LSPAttach",
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
