local M = {}

M.plugins = {
  {
    "mrjones2014/legendary.nvim",
    priority = 10000,
    lazy = false,
  }
}

function M.setup()
  local legendary = require("legendary")
  
  -- Global keymaps configuration
  legendary.setup({
    keymaps = {
      -- Define global keymaps here
    }
  })
end

return M
