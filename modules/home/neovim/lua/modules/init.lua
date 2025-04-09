-- Load all module definitions in dependency order
require("modules.keybindings") -- First, as other modules may register keymaps
require("modules.themes")      -- Second, for UI setup
require("modules.layout")      -- Third, for panel management
-- Add future modules below this line
