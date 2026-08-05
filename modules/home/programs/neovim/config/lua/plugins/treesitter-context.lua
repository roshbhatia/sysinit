return {
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "VeryLazy",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("treesitter-context").setup({
        separator = "",
      })
      vim.cmd("TSContext enable")
    end,
    keys = {
      {
        "go",
        function()
          require("treesitter-context").go_to_context(vim.v.count1)
        end,
        desc = "Go to context",
        silent = true,
      },
    },
  },
}
