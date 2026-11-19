local cjson = require("cjson")
local M = {}

local NAME_PROFILES = {
  ["LG HDR 4K"] = { font_size = 14 },
}

local cached_displays

local function get_displays()
  if cached_displays then
    return cached_displays
  end
  local handle =
    io.popen("/usr/sbin/system_profiler SPDisplaysDataType -json -timeout 2 2>/dev/null")
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
          table.insert(displays, { width = w, height = h, name = d._name or "" })
        end
      end
    end
  end
  cached_displays = displays
  return displays
end

function M.get_font_size(default)
  local displays = get_displays()
  for _, d in ipairs(displays) do
    local profile = NAME_PROFILES[d.name]
    if profile and profile.font_size then
      return profile.font_size
    end
  end
  return default
end

return M
