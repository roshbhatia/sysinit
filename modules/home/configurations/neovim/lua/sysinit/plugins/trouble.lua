return {
  {
    "folke/trouble.nvim",
    opts = {},
    cmd = "Trouble",
    keys = {
      {
        "<leader>cxx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Project diagnostics",
      },
      {
        "<leader>cb",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer diagnostics",
      },
      {
        "<leader>cl",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Loclist diagnostics",
      },
      {
        "<leader>cq",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Qflist diagnostics",
      },
    },
  },
}
