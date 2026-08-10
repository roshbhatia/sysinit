#!/usr/bin/env bash
# Fail when a wezterm viewer chord stops resolving what it is supposed to.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

keybindings="modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua"

command -v luajit > /dev/null 2>&1 || {
  echo "check-wezterm-chords: luajit is not on PATH, skipping" >&2
  exit 0
}

harness=$(mktemp -t wezterm-chords.XXXXXX)
trap 'rm -f "$harness"' EXIT

cat > "$harness" << 'LUA'
-- Stubs, not mocks: each returns the least this module needs to load. A stub
-- that grew behaviour would start testing itself.
package.preload["wezterm"] = function()
  return {
    action = setmetatable({}, {
      __index = function(_, name)
        return function(arg) return { action = name, arg = arg } end
      end,
    }),
    action_callback = function(fn) return fn end,
    log_warn = function() end,
    shell_split = function(s) return { s } end,
    home_dir = "/home/stub",
    gui = nil,
  }
end
package.preload["sysinit.pkg.utils"] = function()
  return {
    get_nix_binary = function(n) return "/nix/bin/" .. n end,
    get_nix_user_bin = function() return "/nix/bin" end,
    get_home_dir = function() return "/home/stub" end,
    get_process_name = function() return nil end,
  }
end
package.preload["sysinit.pkg.plugin_loader"] = function()
  return { load = function() return false, "stub" end }
end

local keybindings = dofile(arg[1])
local config = {}
keybindings.setup(config)

-- The source pane. Its id and directory are what every chord must carry.
local source = {
  pane_id = function() return 7 end,
  get_current_working_dir = function() return "file://host/repo/here/" end,
}

local expected = {
  w = "/nix/bin/sysinit-agent watch wtrun pane-7",
  b = "/nix/bin/sysinit-agent watch bus /repo/here",
}

local seen = {}
for _, binding in ipairs(config.keys) do
  if binding.mods == "SUPER|SHIFT" and expected[binding.key] then
    local spawned
    local win = {
      perform_action = function(_, action) spawned = action end,
      toast_notification = function() end,
    }
    binding.action(win, source)
    assert(spawned and spawned.action == "SplitPane",
      binding.key .. ": spawned no pane")
    local got = table.concat(spawned.arg.command.args, " ")
    assert(got == expected[binding.key],
      binding.key .. ": ran " .. got .. ", want " .. expected[binding.key])
    seen[binding.key] = true
  end
end

for key in pairs(expected) do
  assert(seen[key], "no SUPER|SHIFT " .. key .. " chord in the key table")
end

-- A source the chord cannot name must not open a pane at all. Opening one on an
-- empty argument would put the viewer in the split pane's own directory, which
-- is the failure this whole contract exists to prevent.
local spawned, toasted
local win = {
  perform_action = function(_, action) spawned = action end,
  toast_notification = function() toasted = true end,
}
for _, binding in ipairs(config.keys) do
  if binding.mods == "SUPER|SHIFT" and binding.key == "b" then
    binding.action(win, {
      pane_id = function() return 7 end,
      get_current_working_dir = function() return nil end,
    })
  end
end
assert(not spawned, "a chord with no working directory still opened a pane")
assert(toasted, "a chord with no working directory said nothing")

-- Locked mode passes the key through instead of acting on it, the same as every
-- other chord in this file.
local sent
local locked_win = {
  perform_action = function(_, action) sent = action end,
  toast_notification = function() end,
}
keybindings.locked_mode = true
for _, binding in ipairs(config.keys) do
  if binding.mods == "SUPER|SHIFT" and binding.key == "w" then
    binding.action(locked_win, source)
  end
end
keybindings.locked_mode = false
assert(sent and sent.SendKey and sent.SendKey.key == "w",
  "a locked-mode chord did not pass the key through")
LUA

if ! luajit "$harness" "$keybindings"; then
  echo "wezterm-chords: $keybindings does not resolve its viewer chords." >&2
  echo "The source name must come from the pane the owner pressed the key in." >&2
  exit 1
fi
