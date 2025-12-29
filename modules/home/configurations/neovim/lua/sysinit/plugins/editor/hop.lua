local M = {}

M.plugins = {
  {
    "smoka7/hop.nvim",
    opts = {
      keys = "fjdkslaghrueiwoncmv",
      jump_on_sole_occurrence = false,
    },
    keys = function()
      local hop = require("hop")
      local directions = require("hop.hint").HintDirection

      return {
        {
          "f",
          function()
            hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
          end,
          mode = { "n", "v", "o" },
          desc = "Hop forward to char",
        },
        {
          "F",
          function()
            hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
          end,
          mode = { "n", "v", "o" },
          desc = "Hop backward to char",
        },
        {
          "t",
          function()
            hop.hint_char1({
              direction = directions.AFTER_CURSOR,
              current_line_only = true,
              hint_offset = -1,
            })
          end,
          mode = { "n", "v", "o" },
          desc = "Hop till after char",
        },
        {
          "T",
          function()
            hop.hint_char1({
              direction = directions.BEFORE_CURSOR,
              current_line_only = true,
              hint_offset = 1,
            })
          end,
          mode = { "n", "v", "o" },
          desc = "Hop till before char",
        },
      }
    end,
  },
}

return M
