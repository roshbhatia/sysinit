local M = {}

function M.setup()
  local legendary = require("legendary")

  legendary.setup({
    -- Keymaps will be added by individual modules
    keymaps = {},
    
    -- Command palette configuration
    commands = {},
    
    -- Autocmds can be added here if needed
    autocmds = {},
    
    -- UI Configuration
    ui = {
      border = "rounded",
      width = 0.6,
      height = 0.6,
      
      -- Sorting and filtering
      filter_mode = "fuzzy",
      sort_modifier = ":alpha",
      
      -- Repeat last action
      repeat_last_action = true,
      
      -- Reduce UI clutter
      reduce_ui_clutter = true,
    },
    
    -- Misc settings
    select_prompt = "> ",
    log_level = vim.log.levels.INFO,
  })
end

return M
