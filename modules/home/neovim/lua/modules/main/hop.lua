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

  -- Which-key bindings using V3 format
  local wk = require("which-key")
  wk.add({
    {
      "f",
      function() hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true }) end,
      mode = { "n", "v", "o" },
      desc = "Hop: Forward to char"
    },
    {
      "F",
      function() hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true }) end,
      mode = { "n", "v", "o" },
      desc = "Hop: Backward to char"
    },
    {
      "t",
      function() hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 }) end,
      mode = { "n", "v", "o" },
      desc = "Hop: Forward till char"
    },
    {
      "T",
      function() hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 }) end,
      mode = { "n", "v", "o" },
      desc = "Hop: Backward till char"
    }
  })
end

return M
