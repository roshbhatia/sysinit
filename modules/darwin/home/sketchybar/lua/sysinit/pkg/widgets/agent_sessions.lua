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

-- cjson decodes JSON `null` to a lightuserdata sentinel, NOT to Lua nil, so
-- `not value` is false for a null and any string operation on it raises. That raise
-- happens inside an sbar.exec callback, which sbarLua swallows, so the chip sat
-- visible-and-empty while the command ran correctly every two seconds. Coerce every
-- nullable field through this before use.
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

  -- Count sessions holding a blocked agent, excluding the one already selected:
  -- the owner is looking at that one, so it is not news.
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

-- One exec, not two. The previous shape asked osascript for the front app, cached
-- the answer in a module-level flag, and polled separately -- so the chip depended
-- on two callbacks firing in the right order, and when the first never delivered
-- the item sat visible-but-empty with no branch having run. Asking the shell for
-- both facts in one command removes the ordering and the cache: either the output
-- is a rollup to render, or it is the literal HIDE.
local function poll()
  local cmd = "app=$(osascript -e 'tell application \"System Events\" to get name of first application process whose frontmost is true' 2>/dev/null); "
    .. "case \"$app\" in wezterm-gui|WezTerm|Wezterm) "
    .. agent_sessions_cmd()
    .. " 2>/dev/null | tr -d '\\n' ;; *) echo HIDE ;; esac"
  -- Output is flattened to ONE line. Every widget here that works through
  -- `sbar.exec` returns a single line (front_app, datetime, battery); this one
  -- returned pretty-printed JSON across ~30 lines, and its callback never fired
  -- while a one-line `--set` of the same item rendered correctly. Flattening is the
  -- one remaining difference from the widgets that work.
  sbar.exec(cmd, function(result, _exit_code)
    local text = utils.trim(result or "")
    if text == "" or text == "HIDE" then
      utils.animate_visibility(item, false)
      return
    end
    -- cjson, the same decoder core/display.lua uses. Wrapped in pcall because a
    -- truncated read must dim the chip, not raise out of the event loop.
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

  -- Every tick re-derives the front app inside the one exec, so there is no cached
  -- state to go stale and no ordering between callbacks to get wrong.
  item:subscribe("front_app_switched", poll)
  item:subscribe("routine", poll)
  item:subscribe("forced", poll)

  poll()
end

return M
