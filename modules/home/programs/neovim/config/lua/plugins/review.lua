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
        -- Declared here rather than beside the watcher so lazy loads this plugin
        -- first: the scoped open attaches review.nvim to a codediff session, and a
        -- keymap that ran before the plugin existed would open a plain diff.
        "<leader>dR",
        function()
          require("harness.api").review_touched()
        end,
        desc = "Review: annotate only the files an agent wrote",
      },
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
