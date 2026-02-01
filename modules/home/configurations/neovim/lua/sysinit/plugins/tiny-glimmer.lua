return {
  {
    "rachartier/tiny-glimmer.nvim",
    event = "VeryLazy",
    config = function()
      local hl = vim.api.nvim_get_hl(0, { name = "StatusLineNC" })
      local fg = hl.fg or 0xA5ADCB -- fallback to base04 from Catppuccin

      require("tiny-glimmer").setup({
        transparency_color = string.format("#%06x", fg),
        overwrite = {
          search = { enabled = true },
          undo = { enabled = true, undo_mapping = "u" },
          redo = { enabled = true, redo_mapping = "U" },
        },
      })
    end,
  },
}
