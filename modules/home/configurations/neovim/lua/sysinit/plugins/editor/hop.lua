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
          "<S-CR>",
          function() vim.cmd("HopWord") end,
          mode = "n",
          desc = "Jump to any word",
        },
        {
          "<S-CR>",
          function() vim.cmd("HopAnywhere") end,
          mode = "v",
          desc = "Jump to anywhere",
        },
      }
    end,
  },
}

return M
