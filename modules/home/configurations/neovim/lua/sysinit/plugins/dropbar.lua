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
    keys = function()
      return {
        {
          "<leader>cc",
          function()
            require("dropbar.api").pick()
          end,
          desc = "Pick breadcrumbs",
        },
      }
    end,
  },
}
