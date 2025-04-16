-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/hadronized/hop.nvim/refs/heads/master/doc/hop.txt"
local M = {}

M.plugins = {
  {
    'phaazon/hop.nvim',
    branch = 'v2',
    config = function()
      local hop = require('hop')
      local directions = require('hop.hint').HintDirection
      
      hop.setup({
        keys = 'etovxqpdygfblzhckisuran'
      })
      
      vim.keymap.set({"n","v","o"}, "f", function()
        hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
      end, { desc = "Hop Forward to Char" })
      
      vim.keymap.set({"n","v","o"}, "F", function()
        hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
      end, { desc = "Hop Backward to Char" })
      
      vim.keymap.set({"n","v","o"}, "t", function()
        hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 })
      end, { desc = "Hop Forward Till Char" })
      
      vim.keymap.set({"n","v","o"}, "T", function()
        hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 })
      end, { desc = "Hop Backward Till Char" })
      
      vim.keymap.set("n", "<leader>hw", function()
        hop.hint_words()
      end, { desc = "Hop to Word" })
      
      vim.keymap.set("n", "<leader>hl", function()
        hop.hint_lines()
      end, { desc = "Hop to Line" })
      
      vim.keymap.set("n", "<leader>ha", function()
        hop.hint_anywhere()
      end, { desc = "Hop Anywhere" })
    end
  }
}

return M