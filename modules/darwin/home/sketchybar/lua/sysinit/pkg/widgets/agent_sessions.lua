local sbar = require("sketchybar")
local cjson = require("cjson")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")
local utils = require("sysinit.pkg.utils")

local M = {}

local item

local function agent_sessions_cmd()
  local user = os.getenv("USER")
  if user and user ~= "" then
    return "/etc/profiles/per-user/" .. user .. "/bin/agent-sessions"
  end
  return "agent-sessions"
end

local status_icons = {
  waiting = "󰀦",
  done = "󰄬",
  working = "󰑮",
}

local function str(v)
  return type(v) == "string" and v or nil
end

local function render(payload)
  local selected = str(payload and payload.selected)
  local state = str(payload and payload.selection_state) or "absent"
  local sessions = (payload and type(payload.sessions) == "table") and payload.sessions or {}

  if state == "absent" or not selected or selected == "" then
    utils.animate_visibility(item, false)
    return
  end

  local attention, worst = 0, nil
  for _, s in ipairs(sessions) do
    if type(s.blocked) == "number" and s.blocked > 0 and str(s.name) ~= selected then
      attention = attention + 1
      local r = type(s.rank) == "number" and s.rank or 0
      local wr = worst and type(worst.rank) == "number" and worst.rank or 0
      if not worst or r > wr then
        worst = s
      end
    end
  end

  local label = utils.truncate(selected, 18)
  if attention > 0 then
    label = label .. "  +" .. tostring(attention)
  end

  local color = colors.foreground_primary
  if state == "stale" then
    color = colors.foreground_muted
  end

  local icon = "󰆍"
  local worst_status = worst and str(worst.status)
  if worst_status and status_icons[worst_status] then
    icon = status_icons[worst_status]
  end

  utils.animate(function()
    item:set({
      icon = {
        string = icon,
        font = settings.fonts.icons.regular,
        color = color,
      },
      label = {
        string = label,
        font = settings.fonts.text.regular,
        color = color,
      },
      drawing = true,
    })
  end)
end

-- One poll at a time.
local in_flight = false

local function poll()
  if in_flight then
    return
  end
  in_flight = true

  local cmd = "app=$(timeout 2 osascript -e 'tell application \"System Events\" to get name of first application process "
    .. "whose frontmost is true' 2>/dev/null); "
    .. "case \"$app\" in wezterm-gui|WezTerm|Wezterm) timeout 5 "
    .. agent_sessions_cmd()
    .. " 2>/dev/null | tr -d '\\n' ;; *) echo HIDE ;; esac"
  sbar.exec(cmd, function(result)
    in_flight = false

    if type(result) == "table" then
      render(result)
      return
    end

    local text = utils.trim(tostring(result or ""))
    if text == "" or text == "HIDE" then
      utils.animate_visibility(item, false)
      return
    end

    local ok, payload = pcall(cjson.decode, text)
    if not ok or type(payload) ~= "table" then
      utils.animate_visibility(item, false)
      return
    end
    render(payload)
  end)
end

function M.setup()
  item = sbar.add("item", "agent_sessions", {
    position = "left",
    icon = {
      font = settings.fonts.icons.regular,
      color = colors.foreground_primary,
    },
    label = {
      font = settings.fonts.text.regular,
      color = colors.foreground_primary,
    },
    background = { drawing = false },
    padding_left = settings.spacing.widget_spacing,
    padding_right = settings.spacing.widget_spacing,
    update_freq = 2,
  })

  item:subscribe("front_app_switched", poll)
  item:subscribe("routine", poll)
  item:subscribe("forced", poll)

  poll()
end

return M
