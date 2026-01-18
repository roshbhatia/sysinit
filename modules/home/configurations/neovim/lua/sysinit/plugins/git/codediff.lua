return {
  {
    "esmuellert/codediff.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    cmd = "CodeDiff",
    config = function()
      require("codediff").setup({
        explorer = {
          position = "bottom",
          view_mode = "tree",
        },
        keymaps = {
          view = {
            toggle_explorer = "<localleader>e",
          },
          explorer = {
            toggle_view_mode = "t",
          },
          conflict = {
            accept_incoming = "<localleader>i",
            accept_current = "<localleader>c",
            accept_both = "<localleader>b",
            discard = "<localleader>x",
          },
        },
      })
    end,
    keys = {
      {
        "<leader>dd",
        function()
          vim.cmd("CodeDiff HEAD")
        end,
        desc = "HEAD",
      },
      {
        "<leader>dm",
        function()
          vim.cmd("CodeDiff main")
        end,
        desc = "Main",
      },
    },
  },
}
