package.path = os.getenv("HOME") .. "/.hammerspoon/lua/?.lua;" .. package.path
require("aerospace_switcher").setup()

local VimMode = hs.loadSpoon("VimMode")
local vim = VimMode:new()

vim:bindHotKeys({ enter = { { "cmd" }, "]" } })

vim:shouldDimScreenInNormalMode(true)

vim:disableForApp('Code')
vim:disableForApp('Code - Insiders')
vim:disableForApp('WezTerm')
vim:disableForApp('zoom.us')
vim:disableForApp('Terminal')

-- Configure global window switcher UI
hs.window.switcher.ui.showThumbnails = true
hs.window.switcher.ui.thumbnailSize = 112
hs.window.switcher.ui.showTitles = true
hs.window.switcher.ui.titleBackgroundColor = { 0, 0, 0 }
hs.window.switcher.ui.textColor = { 1, 1, 1 }
hs.window.switcher.ui.showSelectedThumbnail = true
hs.window.switcher.ui.selectedThumbnailSize = 256

-- Window switcher with thumbnails (using cmd+tab)
local windowSwitcher =
  hs.window.switcher.new(hs.window.filter.new():setCurrentSpace(true):setDefaultFilter({}))

local function mapCmdTab(event)
  local flags = event:getFlags()
  local chars = event:getCharacters()

  if chars == "\t" and flags:containExactly({ "cmd" }) then
    windowSwitcher:next()
    return true
  elseif chars == string.char(25) and flags:containExactly({ "cmd", "shift" }) then
    windowSwitcher:previous()
    return true
  end
end

local tapCmdTab = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, mapCmdTab)

tapCmdTab:start()
