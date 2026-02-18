local function get_palette_colors()
  local hl_utils = require("sysinit.utils.highlight")
  return {
    good = hl_utils.get_fg("@variable"),
    error = hl_utils.get_fg("Error"),
  }
end

return {
  {
    "shellRaining/hlchunk.nvim",
    event = {
      "VeryLazy",
    },
    config = function()
      local colors = get_palette_colors()
      require("hlchunk").setup({
        chunk = {
          enable = true,
          use_treesitter = true,
          duration = 100,
          delay = 100,
          style = {
            { fg = colors.good },
            { fg = colors.error },
          },
        },
        indent = {
          enable = false,
        },
        blank = {
          enable = false,
        },
        line_num = {
          enable = false,
        },
      })
    end,
  },
}
