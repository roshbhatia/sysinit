package.path = os.getenv("HOME") .. "/.hammerspoon/lua/?.lua;" .. package.path
require("app_switcher").setup()

-- VimMode.spoon setup
local VimMode = hs.loadSpoon('VimMode')
local vim = VimMode:new()

-- Enter normal mode with ctrl+]
vim:bindHotKeys({ enter = {{'ctrl'}, ']'} })

-- Disable for VSCode Insiders, WezTerm, and Zoom
vim:disableForApp('Visual Studio Code - Insiders')
vim:disableForApp('WezTerm')
vim:disableForApp('zoom.us')

-- Optionally, disable for other terminals/editors
-- vim:disableForApp('Code')
-- vim:disableForApp('MacVim')

-- Optionally, show/hide alert or dim screen
-- vim:shouldShowAlertInNormalMode(false)
-- vim:shouldDimScreenInNormalMode(true)
