return {
  {
    "nvim-mini/mini.surround",
    version = "*",
    event = "VeryLazy",
    opts = {
      mappings = {
        add = "q", -- Add surrounding in Normal and Visual modes
        delete = "qd", -- Delete surrounding
        find = "qf", -- Find surrounding (to the right)
        find_left = "qF", -- Find surrounding (to the left)
        highlight = "qh", -- Highlight surrounding
        replace = "qr", -- Replace surrounding
        update_n_lines = "qn", -- Update `n_lines`
        suffix_last = "l", -- Suffix to search with "prev" method
        suffix_next = "n", -- Suffix to search with "next" method
      },
    },
  },
}
