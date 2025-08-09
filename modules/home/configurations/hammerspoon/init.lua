package.path = os.getenv("HOME") .. "/.hammerspoon/lua/?.lua;" .. package.path
require("aerospace_switcher").setup()

local VimMode = hs.loadSpoon("VimMode")
local vim = VimMode:new()

vim:bindHotKeys({ enter = { { "cmd" }, "]" } })

vim:shouldDimScreenInNormalMode(true)

vim:disableForApp("Code")
vim:disableForApp("Code - Insiders")
vim:disableForApp("WezTerm")
vim:disableForApp("zoom.us")
vim:disableForApp("Terminal")

-- Define the UI preferences in a table
local switcherUIPrefs = {
  showThumbnails = true,
  thumbnailSize = 112,
  showTitles = true,
  titleBackgroundColor = { 0, 0, 0 },
  textColor = { 1, 1, 1 },
  showSelectedThumbnail = true,
  selectedThumbnailSize = 256,
}

local windowSwitcher = hs.window.switcher.new(
  hs.window.filter.new():setCurrentSpace(true):setDefaultFilter({}),
  switcherUIPrefs
)

local function mapCmdTab(event)
  local flags = event:getFlags()
  local chars = event:getCharacters()

  if event:getKeyCode() == hs.keycodes.map["tab"] and flags:containExactly({ "cmd" }) then
    windowSwitcher:next()
    return true
  elseif
    event:getKeyCode() == hs.keycodes.map["tab"] and flags:containExactly({ "cmd", "shift" })
  then
    windowSwitcher:previous()
    return true
  end
end

local tapCmdTab = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, mapCmdTab)

tapCmdTab:start()

