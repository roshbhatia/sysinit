package.path = os.getenv("HOME") .. "/.hammerspoon/lua/?.lua;" .. package.path
require("app_switcher").setup()

local VimMode = hs.loadSpoon("VimMode")
local vim = VimMode:new()

vim:bindHotKeys({ enter = { { "ctrl" }, "]" } })

vim:disableForApp("Visual Studio Code - Insiders")
vim:disableForApp("WezTerm")
vim:disableForApp("zoom.us")

vim:shouldDimScreenInNormalMode(true)

local switcher =
  hs.window.switcher.new(hs.window.filter.new():setCurrentSpace(true):setDefaultFilter({}))
local function mapCmdTab(event)
  local flags = event:getFlags()
  local chars = event:getCharacters()
  if chars == "\t" and flags:containExactly({ "cmd" }) then
    switcher:next()
    return true
  elseif chars == string.char(25) and flags:containExactly({ "cmd", "shift" }) then
    switcher:previous()
    return true
  end
end
local tapCmdTab = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, mapCmdTab)
tapCmdTab:start()
