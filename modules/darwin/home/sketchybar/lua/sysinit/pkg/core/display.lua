local cjson = require("cjson")
local M = {}

-- y_offset: distance from top of screen (below notch) in points
local DISPLAY_PROFILES = {
  { w = 2056, h = 1329, y_offset = 52 },
  { w = 1800, h = 1169, y_offset = 8 },
}

local function get_profile(width, height)
  for _, p in ipairs(DISPLAY_PROFILES) do
    if width == p.w and height == p.h then
      return p
    end
  end
  return nil
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
          table.insert(displays, { width = w, height = h })
        end
      end
    end
  end
  return displays
end

function M.get_y_offset()
  local displays = get_displays()
  for _, d in ipairs(displays) do
    local profile = get_profile(d.width, d.height)
    if profile then
      return profile.y_offset
    end
  end
  return 8
end

return M
