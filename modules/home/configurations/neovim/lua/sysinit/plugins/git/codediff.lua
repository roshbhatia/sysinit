local M = {}

M.plugins = {
  {
    "esmuellert/codediff.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    cmd = "CodeDiff",
    config = function()
      require("codediff").setup({
        keymaps = {
          view = {
            toggle_explorer = "<localleader>et", -- Toggle explorer visibility (explorer mode only)
          },
          explorer = {
            toggle_view_mode = "t",
          },
          conflict = {
            accept_incoming = "<localleader>i", -- Accept incoming (theirs/left) change
            accept_current = "<localleader>c", -- Accept current (ours/right) change
            accept_both = "<localleader>b", -- Accept both changes (incoming first)
            discard = "<localleader>x", -- Discard both, keep base
          },
        },
      })
    end,
    keys = {
      {
        "<leader>dd",
        function()
          vim.cmd("CodeDiff")
        end,
        desc = "Diff: Toggle (HEAD)",
      },
      {
        "<leader>dm",
        function()
          vim.cmd("CodeDiff main")
        end,
        desc = "Diff: Main",
      },
    },
  },
}

return M
