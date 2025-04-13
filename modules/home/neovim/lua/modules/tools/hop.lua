local verify = require("core.verify")

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
  local commander = require("commander")
  local hop = require('hop')
  local directions = require('hop.hint').HintDirection

  -- Register hop commands with commander
  commander.add({
    {
      desc = "Hop Forward to Char",
      cmd = function() 
        hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true }) 
      end,
      keys = { {"n", "v", "o"}, "f" },
      cat = "Hop"
    },
    {
      desc = "Hop Backward to Char",
      cmd = function() 
        hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true }) 
      end,
      keys = { {"n", "v", "o"}, "F" },
      cat = "Hop"
    },
    {
      desc = "Hop Forward Till Char",
      cmd = function() 
        hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 }) 
      end,
      keys = { {"n", "v", "o"}, "t" },
      cat = "Hop"
    },
    {
      desc = "Hop Backward Till Char",
      cmd = function() 
        hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 }) 
      end,
      keys = { {"n", "v", "o"}, "T" },
      cat = "Hop"
    },
    {
      desc = "Hop to Word",
      cmd = function() hop.hint_words() end,
      keys = { "n", "<leader>hw" },
      cat = "Hop"
    },
    {
      desc = "Hop to Line",
      cmd = function() hop.hint_lines() end,
      keys = { "n", "<leader>hl" },
      cat = "Hop"
    },
    {
      desc = "Hop Anywhere",
      cmd = function() hop.hint_anywhere() end,
      keys = { "n", "<leader>ha" },
      cat = "Hop"
    }
  })
  
  -- Register verification steps
  verify.register_verification("hop", {
    {
      desc = "Hop Forward to Char",
      command = "f<char>",
      expected = "Should show hop hints for the specified character"
    },
    {
      desc = "Hop Backward to Char",
      command = "F<char>",
      expected = "Should show hop hints for the specified character in reverse"
    },
    {
      desc = "Hop to Word",
      command = "<leader>hw",
      expected = "Should show hop hints for all words"
    },
    {
      desc = "Commander Integration",
      command = ":Telescope commander filter cat=Hop",
      expected = "Should show Hop commands in Commander palette"
    }
  })
end

return M