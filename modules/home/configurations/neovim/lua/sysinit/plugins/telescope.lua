return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      -- Minimal setup for plugin dependencies (neogit, octo)
      require("telescope").setup({
        defaults = {
          sorting_strategy = "ascending",
          layout_config = {
            prompt_position = "top",
          },
        },
      })
    end,
  },
}
