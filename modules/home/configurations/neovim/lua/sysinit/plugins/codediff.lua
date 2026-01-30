return {
  {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    opts = {
      explorer = {
        view_mode = "tree",
      },
      keymaps = {
        view = {
          toggle_explorer = "<leader>dt",
        },
        conflict = {
          accept_incoming = "<leader>dt",
          accept_current = "<leader>dc",
          accept_both = "<leader>db",
          discard = "<leader>dx",
        },
      },
    },
    keys = {
      {
        "<leader>dd",
        "<Cmd>CodeDiff<CR>",
        desc = "Open repo diff",
      },
      {
        "<leader>dh",
        "<Cmd>Cod%<CR>",
        desc = "Open file history diff",
      },
    },
  },
}
