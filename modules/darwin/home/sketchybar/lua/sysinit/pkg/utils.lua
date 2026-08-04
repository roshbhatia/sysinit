local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

local M = {}

M.animation = {
  curve = "circ",
  duration = 12,
}

function M.separator(name, position, opts)
  opts = opts or {}
  return sbar.add("item", name, {
    position = position,
    icon = {
      string = "|",
      font = settings.fonts.separators.bold,
      color = opts.color or colors.foreground_primary,
      y_offset = settings.separator_y_offset,
    },
    background = { drawing = false },
    label = { drawing = false },
    padding_left = opts.padding_left or settings.spacing.separator_spacing,
    padding_right = opts.padding_right or settings.spacing.separator_spacing,
    drawing = opts.drawing,
  })
end

function M.format_percent(value)
  if value >= 100 then
    return tostring(value) .. "%"
  elseif value >= 10 then
    return " " .. tostring(value) .. "%"
  else
    return "  " .. tostring(value) .. "%"
  end
end

function M.trim(str)
  if not str then
    return ""
  end
  return str:gsub("^%s+", ""):gsub("%s+$", "")
end

function M.truncate(str, max_len)
  if not str then
    return ""
  end
  if #str > max_len then
    return str:sub(1, max_len) .. "…"
  end
  return str
end

function M.animate(callback)
  sbar.animate(M.animation.curve, M.animation.duration, callback)
end

function M.animate_visibility(items, visible)
  if type(items) ~= "table" then
    items = { items }
  end
  sbar.animate(M.animation.curve, M.animation.duration, function()
    for _, item in ipairs(items) do
      item:set({ drawing = visible })
    end
  end)
end

return M
