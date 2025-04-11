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
      -- Disable Python remote plugin for better performance
      wilder.set_option('use_python_remote_plugin', 0)

      -- Better pipeline for performance and fuzzy search
      wilder.set_option('pipeline', {
        wilder.branch(
          wilder.cmdline_pipeline({
            fuzzy = 2,
            fuzzy_filter = wilder.lua_fzy_filter(),
          }),
          wilder.vim_search_pipeline()
        )
      })

      -- Set up proper highlighters
      local highlighters = {
        wilder.pcre2_highlighter(),
        wilder.lua_fzy_highlighter(),
      }

      -- Create a beautiful popupmenu renderer with devicons
      local popupmenu_renderer = wilder.popupmenu_renderer(
        wilder.popupmenu_border_theme({
          border = 'rounded',
          highlights = {
            border = 'Normal',
            default = 'Normal',
          },
          empty_message = wilder.popupmenu_empty_message_with_spinner(),
          highlighter = highlighters,
          left = {
            ' ',
            wilder.popupmenu_devicons(),
            wilder.popupmenu_buffer_flags({
              flags = ' a + ',
              icons = {['+'] = '', a = '', h = ''},
            }),
          },
          right = {
            ' ',
            wilder.popupmenu_scrollbar(),
          },
          max_height = '50%',
          min_height = 0,
          prompt_position = 'top',
          reverse = false,
        })
      )

      -- Create a minimal wildmenu renderer for search
      local wildmenu_renderer = wilder.wildmenu_renderer({
        highlighter = highlighters,
        separator = ' · ',
        left = {' ', wilder.wildmenu_spinner(), ' '},
        right = {' ', wilder.wildmenu_index()},
      })

      -- Use renderer mux to use different renderers for different modes
      wilder.set_option('renderer', wilder.renderer_mux({
        [':'] = popupmenu_renderer,
        ['/'] = wildmenu_renderer,
        ['?'] = wildmenu_renderer,
      }))
    end
  }
}

function M.setup()
  -- Any additional setup logic for wilder
end

return M
