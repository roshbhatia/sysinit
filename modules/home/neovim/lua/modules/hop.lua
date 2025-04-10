local M = {}

M.plugins = {
  {
    'phaazon/hop.nvim',
    branch = 'v2', -- Recommended
    config = function()
      require('hop').setup({
        -- Configuration options
        keys = 'etovxqpdygfblzhckisuran'
      })
    end
  }
}

function M.setup()
  local hop = require('hop')
  local directions = require('hop.hint').HintDirection

  -- Example keymaps
  vim.keymap.set('', 'f', function()
    hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
  end, {remap=true, desc = "Hop: Forward to char"})

  vim.keymap.set('', 'F', function()
    hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
  end, {remap=true, desc = "Hop: Backward to char"})

  vim.keymap.set('', 't', function()
    hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 })
  end, {remap=true, desc = "Hop: Forward till char"})

  vim.keymap.set('', 'T', function()
    hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 })
  end, {remap=true, desc = "Hop: Backward till char"})
end

return M
