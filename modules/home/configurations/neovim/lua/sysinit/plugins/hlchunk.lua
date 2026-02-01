local function get_palette_colors()
  local good = vim.api.nvim_get_hl(0, { name = "@variable", link = false })
  local error = vim.api.nvim_get_hl(0, { name = "Error", link = false })
  return {
    good = string.format("#%06x", good.fg),
    error = string.format("#%06x", error.fg),
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
