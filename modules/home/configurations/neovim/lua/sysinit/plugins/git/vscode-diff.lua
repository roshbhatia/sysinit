local M = {}

M.plugins = {
  {
    "esmuellert/vscode-diff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    config = function()
      require("vscode-diff").setup({})
    end,
    keys = {
      {
        "<leader>gdh",
        function()
          vim.cmd("CodeDiff file HEAD")
        end,
        desc = "Diff current file (HEAD)",
      },
      {
        "<leader>gdm",
        function()
          vim.cmd("CodeDiff file main")
        end,
        desc = "Diff current file (main)",
      },
      {
        "<leader>gdH",
        function()
          vim.cmd("CodeDiff HEAD")
        end,
        desc = "Diff all (HEAD)",
      },
      {
        "<leader>gdM",
        function()
          vim.cmd("CodeDiff main")
        end,
        desc = "Diff all (main)",
      },
    },
  },
}

return M
