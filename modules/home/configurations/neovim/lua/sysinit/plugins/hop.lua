return {
  {
    "smoka7/hop.nvim",
    cmd = {
      "HopWord",
      "HopLine",
    },
    opts = {
      keys = "fjdkslaghrueiwoncmv",
      jump_on_sole_occurrence = false,
      case_sensitive = false,
    },
    keys = function()
      return {
        {
          "f",
          function()
            vim.cmd("HopWord")
          end,
          mode = { "n", "v" },
          desc = "Jump to word",
        },
        {
          "F",
          function()
            vim.cmd("HopLine")
          end,
          mode = { "n", "v" },
          desc = "Jump to line",
        },
      }
    end,
  },
}
