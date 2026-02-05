return {
  {
    "smoka7/hop.nvim",
    cmd = {
      "HopAnywhere",
      "HopLine",
      "HopWord",
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
          mode = { "n" },
          desc = "Jump to word",
        },
        {
          "f",
          function()
            vim.cmd("HopAnywhere")
          end,
          mode = { "v" },
          desc = "Jump to anywhere",
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
