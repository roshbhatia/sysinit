local M = {}

M.plugins = {
  {
    "smoka7/hop.nvim",
    cmd = {
      "HopWord",
      "HopLine",
      "HopChar1",
      "HopPattern",
      "HopNodes",
      "HopAnywhere",
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
          "<CMD>HopWord<CR>",
          mode = "n",
          desc = "Jump to any word",
        },
      }
    end,
  },
}

return M
