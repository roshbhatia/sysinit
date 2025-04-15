local M = {}

M.plugins = {
  {
    'gelguy/wilder.nvim',
    dependencies = {
      'romgrk/fzy-lua-native',
      'nvim-tree/nvim-web-devicons'
    },
    config = function()
      local wilder = require('wilder')
      wilder.setup({modes = {':', '/', '?'}})

      wilder.set_option('pipeline', {
        wilder.branch(
          wilder.cmdline_pipeline({
            fuzzy = 2,
            fuzzy_filter = wilder.lua_fzy_filter(),
          }),
          wilder.vim_search_pipeline()
        )
      })

      local highlighters = {
        wilder.pcre2_highlighter
        (),
        wilder.lua_fzy_highlighter(),
      }

      local popupmenu_renderer = wilder.popupmenu_renderer(
        wilder.popupmenu_palette_theme({
          border = 'rounded',
          max_height = '75%',
          min_height = 0,
          prompt_position = 'bottom',
          reverse = 0,
        })
      )

      local wildmenu_renderer = wilder.wildmenu_renderer({
        highlighter = highlighters,
        separator = ' · ',
        left = {' ', wilder.wildmenu_spinner(), ' '},
        right = {' ', wilder.wildmenu_index()},
      })

      wilder.set_option('renderer', wilder.renderer_mux({
        [':'] = popupmenu_renderer,
        ['/'] = wildmenu_renderer,
        ['?'] = wildmenu_renderer,
      }))
    end
  }
}

return M