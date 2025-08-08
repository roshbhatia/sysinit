package.path = os.getenv("HOME") .. "/.hammerspoon/lua/?.lua;" .. package.path
require("app_switcher").setup()

local VimMode = hs.loadSpoon("VimMode")
local vim = VimMode:new()

vim:bindHotKeys({ enter = { { "ctrl" }, "]" } })

vim:disableForApp("Visual Studio Code - Insiders")
vim:disableForApp("WezTerm")
vim:disableForApp("zoom.us")

vim:shouldDimScreenInNormalMode(true)
