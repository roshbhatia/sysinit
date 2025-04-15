local M = {}

M.plugins = {
  {
    "gelguy/wilder.nvim",
    event = "CmdlineEnter",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local wilder = require('wilder')
      wilder.setup({ modes = { ':', '/', '?' } })

      -- Basic configuration
      wilder.set_option('pipeline', {
        wilder.branch(
          wilder.cmdline_pipeline(),
          wilder.search_pipeline()
        ),
      })

      -- Simple renderer
      wilder.set_option('renderer', wilder.wildmenu_renderer({
        highlighter = wilder.basic_highlighter(),
        separator = ' · ',
      }))
    end
  }
}

return M
