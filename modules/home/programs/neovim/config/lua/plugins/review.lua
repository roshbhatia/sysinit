-- Inline review annotations on a codediff.nvim diff.
--
-- The loop this closes: an agent writes code, you walk the diff, you drop typed
-- comments on the lines that need work, and the whole batch goes to the agent
-- pane as one message. That beats retyping "line 51 is wrong" into a chat box.
--
-- `send_sidekick` is disabled because the harness owns the send path; use
-- <leader>jR to route the batch to whichever agent is currently active.
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
