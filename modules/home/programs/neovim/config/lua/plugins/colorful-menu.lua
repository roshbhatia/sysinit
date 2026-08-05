return {
  {
    "xzbdmw/colorful-menu.nvim",
    event = "InsertEnter",
    config = function()
      require("colorful-menu").setup({})
    end,
  },
}
