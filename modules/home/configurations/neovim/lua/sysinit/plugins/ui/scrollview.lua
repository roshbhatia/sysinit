return {
  {
    "dstein64/nvim-scrollview",
    event = "VeryLazy",
    config = function()
      require("scrollview").setup({
        excluded_filetypes = { "neo-tree" },
        signs_on_startup = {},
      })
    end,
  },
}
