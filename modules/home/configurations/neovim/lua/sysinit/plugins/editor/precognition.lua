local M = {}

M.plugins = {
  {
    "tris203/precognition.nvim",
    opts = {
      startVisible = true,
      gutterHints = {
        G = { text = "G", prio = 0 },
        gg = { text = "gg", prio = 0 },
        PrevParagraph = { text = "{", prio = 0 },
        NextParagraph = { text = "}", prio = 0 },
      },
      disabled_fts = {
        "alpha",
      },
    },
    event = "VeryLazy",
  },
}

return M
