-- Core initialization for Neovim
-- This file loads all core modules

-- Load core modules
require("core.options")
require("core.keymaps")
require("core.autocmds")

-- Return the module
return {
  setup = function()
    -- Any additional setup that needs to happen after plugins load
  end
}