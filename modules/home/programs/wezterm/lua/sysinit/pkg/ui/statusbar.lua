local wezterm = require("wezterm")
local ui_format = require("sysinit.pkg.ui.format")
local ui_panes = require("sysinit.pkg.ui.panes")

local M = {}

function M.agent_status(sessions)
  local now = os.time()
  local best, count = nil, 0
  for _, st in pairs(sessions) do
    if st.rank >= ui_panes.state_rank.working then
      count = count + 1
      if not best or st.rank > best.rank or (st.rank == best.rank and (st.since or now) < (best.since or now)) then
        best = st
      end
    end
  end
  if not best then
    return ""
  end
  local icon = ui_format.state_icons[best.status] or "●"
  local text = " " .. icon
  if count > 1 then
    text = text .. " " .. count
  end
  return wezterm.format({ { Text = text .. " " } })
end

local CHIP_NAME_MAX = 16
local CHIP_SESSIONS_MAX = 20

-- Empty when the chip label already says it.
local function chip_sessions(st, workspace)
  local names = st and st.names or nil
  if not names or #names == 0 then
    return ""
  end
  if #names == 1 and names[1] == workspace then
    return ""
  end
  local text = table.concat(names, ",")
  if #text > CHIP_SESSIONS_MAX then
    text = text:sub(1, CHIP_SESSIONS_MAX - 1) .. "…"
  end
  return "[" .. text .. "]"
end

function M.session_chips(window, sessions, slots, colors)
  local ordered = {}
  for name, slot in pairs(slots) do
    ordered[#ordered + 1] = { name = name, slot = slot }
  end
  if #ordered == 0 then
    return ""
  end
  table.sort(ordered, function(a, b)
    return a.slot < b.slot
  end)

  local active = ""
  pcall(function()
    active = window:active_workspace()
  end)

  local items = {}
  for _, entry in ipairs(ordered) do
    local st = sessions[entry.name]
    local status = st and st.status or nil
    local is_active = entry.name == active
    local label = entry.name
    if #label > CHIP_NAME_MAX then
      label = label:sub(1, CHIP_NAME_MAX - 1) .. "…"
    end
    local rank = status and ui_panes.state_rank[status] or 0
    local needs_attention = rank >= ui_panes.state_rank.done
    local sc = ui_format.status_color(status, colors) or colors.idle
    local fg
    if needs_attention then
      fg = sc
    elseif is_active then
      fg = colors.name
    else
      fg = colors.chrome
    end
    items[#items + 1] = { Attribute = { Underline = is_active and "Single" or "None" } }
    items[#items + 1] = { Attribute = { Intensity = (is_active or needs_attention) and "Bold" or "Normal" } }
    items[#items + 1] = { Foreground = { Color = fg } }
    items[#items + 1] = { Text = "  " .. tostring(entry.slot) .. " " }
    items[#items + 1] = { Foreground = { Color = sc } }
    items[#items + 1] = { Text = status and (ui_format.state_icons[status] or "●") or "·" }
    items[#items + 1] = { Foreground = { Color = fg } }
    items[#items + 1] = { Text = " " .. label }
    local inside = chip_sessions(st, entry.name)
    if inside ~= "" then
      items[#items + 1] = { Attribute = { Intensity = "Normal" } }
      items[#items + 1] = { Foreground = { Color = colors.chrome } }
      items[#items + 1] = { Text = " " .. inside }
    end
  end
  items[#items + 1] = { Text = " " }
  return wezterm.format(items)
end
return M
