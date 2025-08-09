package.path = os.getenv("HOME") .. "/.hammerspoon/lua/?.lua;" .. package.path
require("aerospace_switcher").setup()

local VimMode = hs.loadSpoon("VimMode")
local vim = VimMode:new()

vim:bindHotKeys({ enter = { { "cmd" }, "]" } })

vim:shouldDimScreenInNormalMode(true)

-- Window switcher with thumbnails (using cmd+tab)
local windowSwitcher =
  hs.window.switcher.new(hs.window.filter.new():setCurrentSpace(true):setDefaultFilter({}), {
    showThumbnails = true,
    thumbnailSize = 112,
    showTitles = true,
    titleBackgroundColor = { 0, 0, 0 },
    textColor = { 1, 1, 1 },
  })

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
