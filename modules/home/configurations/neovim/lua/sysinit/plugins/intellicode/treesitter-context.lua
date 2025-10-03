local M = {}

M.plugins = {
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("treesitter-context").setup({
        separator = "",
      })

      vim.cmd("TSContext enable")
    end,
  },
  keys = function()
    return {
      {
        "go",
        function()
          require("treesitter-context").go_to_context(vim.v.count1)
        end,
        desc = "Go to context",
        silent = true,
      },
    }
  end,
}

return M
