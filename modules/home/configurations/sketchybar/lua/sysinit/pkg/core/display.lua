local M = {}

local function get_displays()
  local handle = io.popen("sketchybar --query displays")
  if not handle then return {} end
  local result = handle:read("*a")
  handle:close()
  local displays = {}
  for display in result:gmatch('{(.-)}') do
    local id = display:match('id%s*=%s*(%d+)')
    local notch = display:match('notch%s*=%s*(%a+)')
    table.insert(displays, { id = tonumber(id), notch = notch == 'true' })
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
