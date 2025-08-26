local M = {}

M.plugins = {
  {
    "f-person/git-blame.nvim",
    event = "VeryLazy",
    config = function()
      require("gitblame").setup({
        enabled = true,
        message_template = "<summary> by <author> in <<sha>>",
      })

      vim.g.gitblame_display_virtual_text = 0
    end,
  },
}

return M
