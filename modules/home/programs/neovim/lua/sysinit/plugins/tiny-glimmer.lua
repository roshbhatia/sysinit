return {
  {
    "rachartier/tiny-glimmer.nvim",
    event = "VeryLazy",
    config = function()
      local hl_utils = require("sysinit.utils.highlight")

      require("tiny-glimmer").setup({
        transparency_color = hl_utils.get_fg("Normal"),
        overwrite = {
          search = { enabled = true },
          undo = { enabled = true, undo_mapping = "u" },
          redo = { enabled = true, redo_mapping = "U" },
        },
      })
    end,
  },
}
