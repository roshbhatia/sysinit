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

      -- Enable history for command mode
      wilder.set_option('history', 1000)

      -- Set up pipeline for filtering and sorting candidates
      wilder.set_option('pipeline', {
        wilder.branch(
          wilder.cmdline_pipeline({
            -- 0: no fuzzy, 1: fuzzy, 2: fuzzy + case insensitive
            fuzzy = 2,
            set_pcre2_pattern = 1,
            fuzzy_filter = wilder.lua_fzy_filter(),
          }),
          wilder.vim_search_pipeline()
        )
      })

      -- Customize highlighting
      local highlighters = {
        wilder.pcre2_highlighter(),
        wilder.lua_fzy_highlighter(),
      }

      -- Configure popup menu and add icons
      local devicons = require('nvim-web-devicons')
      
      local get_icons = function(name, ext)
        local icon, icon_hl = devicons.get_icon(name, ext)
        return icon, icon_hl
      end

      -- Configure the Command Palette (Experimental) style popup
      local palette_theme = wilder.popupmenu_palette_theme({
        -- 'single', 'double', 'rounded' or 'solid'
        border = 'rounded',
        max_height = '70%',      -- max height of the palette
        min_height = 0,          -- set to the same as 'max_height' for a fixed height window
        prompt_position = 'top', -- 'top' or 'bottom' to set the location of the prompt
        reverse = 0,             -- set to 1 to reverse the order of the list
        -- Highlight the selected item
        selected_item_label_hl = 'Visual',
      })
      
      local palette_renderer = wilder.popupmenu_renderer(
        palette_theme,
        wilder.popupmenu_border_theme({
          highlights = {
            border = 'Normal', -- highlight to use for the border
            accent = wilder.make_hl('WilderAccent', 'Pmenu', {{a = 1}, {a = 1}, {foreground = '#f4468f'}}),
          },
          -- 'single', 'double', 'rounded' or 'solid'
          border = 'rounded',
          empty_message = wilder.popupmenu_empty_message_with_spinner(),
          highlighter = highlighters,
          left = {
            ' ',
            wilder.popupmenu_devicons(get_icons),
            wilder.popupmenu_buffer_flags({
              flags = ' a + ',
              icons = {['+'] = '', a = '', h = ''},
            }),
          },
          right = {
            ' ',
            wilder.popupmenu_scrollbar(),
          },
        })
      )

      local wildmenu_renderer = wilder.wildmenu_renderer({
        highlighter = highlighters,
        separator = ' · ',
        left = {' ', wilder.wildmenu_spinner(), ' '},
        right = {' ', wilder.wildmenu_index()},
      })

      -- Set up different renderers based on the mode
      wilder.set_option('renderer', wilder.renderer_mux({
        [':'] = palette_renderer,
        ['/'] = wildmenu_renderer,
        ['?'] = wildmenu_renderer,
      }))
    end
  }
}

function M.setup()
  -- Add wilder-specific keymaps
  vim.api.nvim_set_keymap('c', '<Tab>', [[wilder#in_context() ? wilder#next() : '<Tab>']],
    { noremap = true, expr = true })
  vim.api.nvim_set_keymap('c', '<S-Tab>', [[wilder#in_context() ? wilder#previous() : '<S-Tab>']],
    { noremap = true, expr = true })
  
  -- Additional keymaps to navigate in the menu
  vim.api.nvim_set_keymap('c', '<C-j>', [[wilder#in_context() ? wilder#next() : '<C-j>']],
    { noremap = true, expr = true })
  vim.api.nvim_set_keymap('c', '<C-k>', [[wilder#in_context() ? wilder#previous() : '<C-k>']],
    { noremap = true, expr = true })
  
  -- Register with which-key if available
  local status, wk = pcall(require, "which-key")
  if status then
    wk.register({
      ["<leader>;"] = { ":", "Command Palette", silent = false, expr = false },
    })
  end
  
  -- Add a note to explicitly configure wilder for command palette
  vim.api.nvim_create_user_command("ConfigWilderPalette", function()
    local status, wilder = pcall(require, "wilder")
    if status then
      -- This explicitly sets the Command Palette style renderer
      wilder.set_option('renderer', wilder.popupmenu_renderer(
        wilder.popupmenu_palette_theme({
          border = 'rounded',
          max_height = '75%',
          min_height = 0,
          prompt_position = 'top',
          reverse = 0,
        })
      ))
      print("Wilder Command Palette configured!")
    else
      print("Wilder is not available")
    end
  end, {})
  
  -- If which-key is available, add this command
  if status then
    wk.register({
      ["<leader>wc"] = { "<cmd>ConfigWilderPalette<CR>", "Configure Wilder Command Palette" },
    })
  end
end

return M
