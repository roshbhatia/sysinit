local M = {}

local vim = nil

function M.setup()
  local VimMode = hs.loadSpoon("VimMode")
  if not VimMode then
    hs.console.printStyledtext("Warning: VimMode spoon not found")
    return
  end

  vim = VimMode:new()

  vim:bindHotKeys({ enter = { { "cmd" }, "]" } })
  vim:shouldDimScreenInNormalMode(true)

  vim:disableForApp("Code")
  vim:disableForApp("Code - Insiders")
  vim:disableForApp("WezTerm")
  vim:disableForApp("zoom.us")
  vim:disableForApp("Terminal")
end

return M
