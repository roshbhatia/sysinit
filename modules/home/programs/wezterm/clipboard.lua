local wezterm = require("wezterm")
local act = wezterm.action

local clipboard_kind = [[
ObjC.import("AppKit");
var types = ObjC.deepUnwrap($.NSPasteboard.generalPasteboard.types) || [];
var image = ["public.tiff", "public.png", "public.jpeg"].some(t => types.includes(t));
image && !types.includes("public.utf8-plain-text") ? "image" : "other";
]]

local function paste(window, pane)
  local action = act.PasteFrom("Clipboard")
  local domain = pane:get_domain_name()
  if domain == "local" or domain == "unix" then
    local panes = require("sysinit.pkg.ui.panes")
    local _, cwd = panes.pane_repo(pane)
    local facts = panes.facts(pane:pane_id(), cwd)
    if facts.live_agent == "codex" or (not facts.process_observable and facts.agent == "codex") then
      local ok, kind = wezterm.run_child_process({
        "/usr/bin/osascript",
        "-l",
        "JavaScript",
        "-e",
        clipboard_kind,
      })
      if ok and kind:match("^image%s*$") then
        action = act.SendKey({ key = "v", mods = "CTRL" })
      end
    end
  end
  window:perform_action(action, pane)
end

return function(config)
  local actions = { c = act.CopyTo("Clipboard"), v = wezterm.action_callback(paste) }
  for _, binding in ipairs(config.keys) do
    if binding.mods == "SUPER" and actions[binding.key] then
      binding.action = actions[binding.key]
    end
  end
end
