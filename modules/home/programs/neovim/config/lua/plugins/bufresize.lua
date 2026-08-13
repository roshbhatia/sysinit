return {
  {
    -- Neovim rescales windows itself when the terminal changes size, and the rounding
    -- drifts: a WezTerm pane dragged a few times leaves one split a line tall. This keeps
    -- the layout in proportion instead, which is what deliberately uneven splits need and
    -- what `wincmd =` would flatten.
    "kwkarlwang/bufresize.nvim",
    event = "VeryLazy",
    config = function()
      require("bufresize").setup()
    end,
  },
}
