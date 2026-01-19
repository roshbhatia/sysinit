return {
  {
    "smoka7/hop.nvim",
    cmd = {
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
          mode = "n",
          desc = "Hop word jump",
        },
      }
    end,
  },
}
