local M = {}

M.plugins = {
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      {
        "<leader>gg",
        function()
          require("neogit").open()
        end,
        desc = "Git: Toggle",
        mode = "n",
      },
      {
        "<leader>gc",
        function()
          require("neogit").open({ "commit" })
        end,
        desc = "Git: Commit",
        mode = "n",
      },
      {
        "<leader>gp",
        function()
          require("neogit").open({ "push" })
        end,
        desc = "Git: Push",
        mode = "n",
      },
      {
        "<leader>gP",
        function()
          require("neogit").open({ "pull" })
        end,
        desc = "Git: Pull",
        mode = "n",
      },
      {
        "<leader>ge",
        function()
          require("neogit").open({ "branch" })
        end,
        desc = "Git: Branch",
        mode = "n",
      },
      {
        "<leader>gl",
        function()
          require("neogit").open({ "log" })
        end,
        desc = "Git: Log",
        mode = "n",
      },
    },
    config = function()
      require("neogit").setup({})
    end,
  },
}

return M
