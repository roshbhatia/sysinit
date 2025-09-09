local M = {}
local cjson = require("cjson")

local NOTCH_DIMENSIONS = {
  { w = 2056, h = 1329 },
}

local function has_notch(width, height)
  for _, dim in ipairs(NOTCH_DIMENSIONS) do
    if width == dim.w and height == dim.h then
      return true
    end
  end
  return false
end

local function get_displays()
  local handle = io.popen("sketchybar --query displays")
  if not handle then
    return {}
  end
  local result = handle:read("*a")
  handle:close()

  local ok, displays_data = pcall(cjson.decode, result)
  if not ok then
    return {}
  end

  local displays = {}
  for _, display in ipairs(displays_data) do
    local frame = display.frame
    local notch = has_notch(frame.w, frame.h)
    table.insert(displays, {
      id = display.DirectDisplayID,
      notch = notch,
      width = frame.w,
      height = frame.h,
    })
  end
  return displays
end

function M.get_y_offset()
  local displays = get_displays()
  for _, d in ipairs(displays) do
    if d.notch then
      return 48
    end
  end
  return 8
end

return M
