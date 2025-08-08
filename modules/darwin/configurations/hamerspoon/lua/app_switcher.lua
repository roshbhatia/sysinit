local M = {}
local theme = dofile(os.getenv("HOME") .. "/.hammerspoon/theme.lua")
hs.window.switcher.ui.backgroundColor = theme.backgroundColor
hs.window.switcher.ui.highlightColor = theme.highlightColor
hs.window.switcher.ui.showThumbnails = theme.showThumbnails
hs.window.switcher.ui.showSelectedTitle = theme.showSelectedTitle
local switcher = hs.window.switcher.new()
function M.setup()
  hs.hotkey.bind(
    { "cmd" },
    "tab",
    function()
      switcher:next()
    end,
    nil,
    function()
      switcher:next()
    end
  )
  hs.hotkey.bind(
    { "cmd", "shift" },
    "tab",
    function()
      switcher:previous()
    end,
    nil,
    function()
      switcher:previous()
    end
  )
end
return M
