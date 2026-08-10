return {
  {
    "Bekaboo/dropbar.nvim",
    branch = "master",
    event = "VimEnter",
    opts = {
      icons = {
        ui = {
          bar = {
            separator = "  ",
            extends = "…",
          },
        },
      },
      menu = {
        scrollbar = {
          enable = false,
        },
      },
    },
    keys = {
      {
        "<leader>cc",
        function()
          require("dropbar.api").pick()
        end,
        desc = "Pick breadcrumbs",
      },
    },
  },
}
