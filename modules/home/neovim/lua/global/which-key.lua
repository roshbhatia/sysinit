local M = {}

function M.setup()
  local wk = require("which-key")

  -- Global which-key configuration
  wk.setup({
    -- Delay for showing which-key popup
    triggers_blacklist = {
      i = { "j", "k" },
      v = { "j", "k" },
    },
    
    -- Window configuration
    window = {
      border = "rounded",
      position = "bottom",
      margin = { 1, 0, 1, 0 },
      padding = { 2, 2, 2, 2 },
    },
    
    -- Layout
    layout = {
      height = { min = 4, max = 25 },
      width = { min = 20, max = 50 },
      spacing = 3,
      align = "left",
    },
    
    -- Ignore certain built-in keys
    ignore_missing = false,
    
    -- Show help hint
    show_help = true,
    
    -- Trigger on leader key
    triggers = { "<leader>" },
    
    -- Preset configurations
    presets = {
      operators = true,
      motions = true,
      text_objects = true,
      windows = true,
      nav = true,
      z = true,
      g = true,
    },
  })

  -- Global leader key groups
  wk.register({
    ["<leader>"] = {
      f = { name = "+Find" },
      g = { name = "+Git" },
      w = { name = "+Windows" },
      t = { name = "+Tabs" },
      d = { name = "+Diagnostics" },
      c = { name = "+Code" },
      s = { name = "+Search" },
      q = { name = "+Quit/Session" },
    }
  })
end

return M
