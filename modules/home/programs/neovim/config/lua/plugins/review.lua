return {
  {
    "georgeguimaraes/review.nvim",
    version = "*",
    dependencies = { "esmuellert/codediff.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "Review" },
    opts = {
      keymaps = {
        send_sidekick = false,
      },
    },
    keys = {
      { "<leader>dr", "<Cmd>Review<CR>", desc = "Review: annotate working diff" },
      {
        "<leader>jR",
        function()
          require("harness.api").send_review()
        end,
        desc = "Harness: send review comments to active agent",
      },
    },
  },
}
