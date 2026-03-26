local cjson = require("cjson")
local M = {}

local DISPLAY_WITH_NOTCH_DIMENSIONS = {
  { w = 2056, h = 1329 },
}

local function has_notch(width, height)
  for _, dim in ipairs(DISPLAY_WITH_NOTCH_DIMENSIONS) do
    if width == dim.w and height == dim.h then
      return true
    end
  end
  return false
end

local function get_displays()
  local handle = io.popen("system_profiler SPDisplaysDataType -json 2>/dev/null")
  if not handle then
    return {}
  end
  local result = handle:read("*a")
  handle:close()

  local ok, data = pcall(cjson.decode, result)
  if not ok or not data.SPDisplaysDataType then
    return {}
  end

  local displays = {}
  for _, gpu in ipairs(data.SPDisplaysDataType) do
    if gpu.spdisplays_ndrvs then
      for _, d in ipairs(gpu.spdisplays_ndrvs) do
        local w, h = (d._spdisplays_resolution or ""):match("(%d+)%s*x%s*(%d+)")
        w, h = tonumber(w), tonumber(h)
        if w and h then
          table.insert(displays, {
            notch = has_notch(w, h),
            width = w,
            height = h,
          })
        end
      end
    end
  end
  return displays
end

function M.get_y_offset()
  local displays = get_displays()
  for _, d in ipairs(displays) do
    if d.notch then
      return 52
    end
  end
  return 8
end

return M
