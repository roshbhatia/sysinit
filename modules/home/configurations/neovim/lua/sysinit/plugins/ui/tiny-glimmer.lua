local M = {}

M.plugins = {
  {
    "rachartier/tiny-glimmer.nvim",
    event = "VeryLazy",
    config = function()
      require("tiny-glimmer").setup({
        overwrite = {
          search = {
            enabled = true,
          },
          undo = {
            enabled = true,
            undo_mapping = "u",
          },
          redo = {
            enabled = true,
            redo_mapping = "U",
          },
        },
        transparency_color = string.format("#%06x", vim.api.nvim_get_hl(0, ({ name = "Normal", link = false }).bg)),
      })
    end,
  },
}

return M
