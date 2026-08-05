return {
  {
    "smoka7/hop.nvim",
    cmd = {
      "HopAnywhere",
      "HopLine",
      "HopWord",
      "HopNodes",
    },
    opts = {
      keys = "fjdkslaghrueiwoncmv",
      jump_on_sole_occurrence = false,
      case_sensitive = false,
    },
    keys = {
      { "f", "<cmd>HopWord<cr>", mode = { "n", "v" }, desc = "Jump to word" },
      { "t", "<cmd>HopAnywhere<cr>", mode = { "n", "v" }, desc = "Jump to anywhere" },
      { "@", "<cmd>HopNodes<cr>", mode = { "v" }, desc = "Jump to node" },
      { "F", "<cmd>HopLine<cr>", mode = { "n", "v" }, desc = "Jump to line" },
    },
  },
}
