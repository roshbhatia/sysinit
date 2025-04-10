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
      wilder.setup({
        modes = {':', '/', '?'},
        next_key = '<Tab>',
        prev_key = '<S-Tab>',
        accept_key = '<Down>',
        reject_key = '<Up>',
      })

      wilder.set_option('renderer', wilder.popupmenu_renderer(
        wilder.popupmenu_border_theme({
          border = 'rounded',
          highlights = {
            border = 'Normal', -- highlight to use for the border
          },
          -- 'single', 'double', 'rounded' or 'solid'
          max_height = '30%',      -- max height of the palette
          min_height = 0,          -- min height of the palette
          prompt_position = 'top', -- 'top' or 'bottom' to set the location of the prompt
          reverse = 0,             -- set to 1 to reverse the order of the list
        })
      ))

      -- Use fzy for matching
      wilder.set_option('pipeline', {
        wilder.branch(
          wilder.cmdline_pipeline({
            language = 'python',
            fuzzy = 1,
          }),
          wilder.python_search_pipeline()
        )
      })
    end
  }
}

function M.setup()
  -- Any additional setup logic for wilder
end

return M
