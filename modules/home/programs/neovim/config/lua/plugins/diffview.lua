return {
  {
    "sindrets/diffview.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = {
      "Review",
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFileHistory",
      "DiffviewRefresh",
    },
    config = function()
      require("harness.diffview").setup()
    end,
    keys = {
      {
        "<leader>dd",
        function()
          require("harness.review").toggle()
        end,
        desc = "Toggle diff",
        mode = "n",
      },
      {
        "<leader>dc",
        function()
          require("harness.changes").quickfix()
        end,
        desc = "Changed files",
        mode = "n",
      },
      {
        "<leader>dC",
        function()
          require("harness.changes").pick()
        end,
        desc = "Find changed file",
        mode = "n",
      },
      {
        "<leader>dh",
        function()
          require("harness.review").history()
        end,
        desc = "File history",
        mode = "n",
      },
      {
        "<leader>dH",
        function()
          require("harness.history").open()
        end,
        desc = "Project history",
        mode = "n",
      },
      {
        "]r",
        function()
          require("harness.review").cycle(1)
        end,
        desc = "Next repo",
        mode = "n",
      },
      {
        "[r",
        function()
          require("harness.review").cycle(-1)
        end,
        desc = "Previous repo",
        mode = "n",
      },
    },
  },
}
