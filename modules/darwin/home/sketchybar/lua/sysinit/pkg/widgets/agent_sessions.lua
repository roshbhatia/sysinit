-- Which seshy session is selected, and how many others need attention.
--
-- The rollup lives in WezTerm's Lua, which sketchybar cannot call, so this polls
-- `agent-sessions` instead. That command reads the same per-pane state bus and
-- `sy list` that WezTerm's own statusline reads, so the bar and the SUPER+s tree
-- cannot disagree about which session is worst.
--
-- Shown only while WezTerm is the front app: outside the terminal the selection is
-- not actionable, and a permanent chip would just be noise.
--
-- The heartbeat is why this can be trusted. `selection_state` distinguishes a live
-- WezTerm from one that quit while leaving its last selection behind, so a stale
-- name is dimmed rather than presented as current. Without it the bar would show
-- the last-focused session forever.
local sbar = require("sketchybar")
local cjson = require("cjson")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")
local utils = require("sysinit.pkg.utils")

local M = {}

local item

-- launchd hands sketchybar a PATH containing the literal string
-- "/etc/profiles/per-user/$USER/bin", and launchd does not expand variables, so that
-- entry names a directory that does not exist and a bare `agent-sessions` never
-- resolves. Build the real path from $USER, which Lua can read, rather than hoping
-- the inherited PATH is usable. Not a fallback chain: one deterministic path.
local function agent_sessions_cmd()
  local user = os.getenv("USER")
  if user and user ~= "" then
    return "/etc/profiles/per-user/" .. user .. "/bin/agent-sessions"
  end
  return "agent-sessions"
end

-- Worst-wins, matching the notifier and the switcher: waiting means the owner must
-- act, done means it is their move, working means it is still going.
local status_icons = {
  waiting = "󰀦",
  done = "󰄬",
  working = "󰑮",
}

local is_wezterm = false

local function render(payload)
  local selected = payload and payload.selected or nil
  local state = payload and payload.selection_state or "absent"
  local sessions = (payload and payload.sessions) or {}

  if not is_wezterm or state == "absent" or not selected then
    utils.animate_visibility(item, false)
    return
  end

  -- Count sessions holding a blocked agent, excluding the one already selected:
  -- the owner is looking at that one, so it is not news.
  local attention, worst = 0, nil
  for _, s in ipairs(sessions) do
    if (s.blocked or 0) > 0 and s.name ~= selected then
      attention = attention + 1
      if not worst or (s.rank or 0) > (worst.rank or 0) then
        worst = s
      end
    end
  end

  local label = utils.truncate(selected, 18)
  if attention > 0 then
    label = label .. "  +" .. tostring(attention)
  end

  -- A stale selection is dimmed, never hidden and never shown as current. Hiding
  -- would be indistinguishable from "no sessions"; showing it plainly would be a
  -- lie about which session is focused.
  local color = colors.foreground_primary
  if state == "stale" then
    -- foreground_muted, not a guessed key with an `or` fallback: a wrong key would
    -- fall back to the primary colour and render stale identically to fresh, which
    -- silently defeats the heartbeat this widget exists to respect.
    color = colors.foreground_muted
  end

  local icon = "󰆍"
  if worst and status_icons[worst.status] then
    icon = status_icons[worst.status]
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

local function poll()
  if not is_wezterm then
    utils.animate_visibility(item, false)
    return
  end
  -- Never blocks the bar: a timeout renders as absent rather than a stuck chip,
  -- and a non-zero exit is treated the same way. `agent-sessions` is written to
  -- always exit 0, so a failure here means something worse than "no sessions".
  sbar.exec(agent_sessions_cmd() .. " 2>/dev/null", function(result, exit_code)
    if exit_code ~= 0 or not result or utils.trim(result) == "" then
      utils.animate_visibility(item, false)
      return
    end
    -- cjson, the same decoder core/display.lua uses. Wrapped in pcall because a
    -- truncated read must dim the chip, not raise out of the event loop.
    local ok, payload = pcall(cjson.decode, result)
    if not ok or type(payload) ~= "table" then
      utils.animate_visibility(item, false)
      return
    end
    render(payload)
  end)
end

local function front_app_changed()
  sbar.exec(
    "osascript -e 'tell application \"System Events\" to get name of first application process whose frontmost is true'",
    function(result, exit_code)
      if exit_code ~= 0 then
        return
      end
      local app = utils.trim(result)
      is_wezterm = app == "wezterm-gui" or app == "WezTerm" or app == "Wezterm"
      poll()
    end
  )
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
    -- Polled rather than event-driven: agent state changes in a pane, not in
    -- anything sketchybar can subscribe to. 2s matches how fast the notifier
    -- reacts, so the chip is never conspicuously behind a toast.
    update_freq = 2,
    -- Deliberately NOT created with `drawing = false`: sketchybar does not deliver
    -- `routine` to a hidden item, so an item that starts hidden never polls and can
    -- therefore never decide to show itself. That deadlock is why this chip stayed
    -- dark while the command behind it worked perfectly. Every other polling widget
    -- here (datetime, battery) also starts visible.
    --
    -- The setup call below hides it immediately when WezTerm is not the front app,
    -- so the visible-by-default state lasts one tick at most.
  })

  -- Every tick re-derives the front app rather than trusting the cached value.
  -- Subscribing the tick to `poll` alone made the chip depend on startup ordering:
  -- if WezTerm was not frontmost the instant sketchybar restarted, `is_wezterm`
  -- stayed false and nothing but an app switch could correct it, so the chip stayed
  -- hidden while the command was working perfectly.
  item:subscribe("front_app_switched", front_app_changed)
  item:subscribe("routine", front_app_changed)
  item:subscribe("forced", front_app_changed)

  front_app_changed()
end

return M
