return {
  {
    "rachartier/tiny-glimmer.nvim",
    event = "VeryLazy",
    config = function()
      local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
      local normal_bg = normal_hl.bg

      require("tiny-glimmer").setup({
        transparency_color = string.format("#%06x", normal_bg),
        overwrite = {
          search = { enabled = true },
          undo = { enabled = true, undo_mapping = "u" },
          redo = { enabled = true, redo_mapping = "U" },
        },
      })
    end,
  },
}
