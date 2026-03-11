local wezterm = require("wezterm")

local M = {}

local sessionizer = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer.wezterm")

-- Generator: reads ~/.local/state/sesh/sessions/ and returns one entry per session directory.
-- Gracefully returns an empty table when the directory is absent.
local function sesh_sessions_generator()
  local sessions_dir = wezterm.home_dir .. "/.local/state/sesh/sessions"
  local entries = {}
  local ok, paths = pcall(wezterm.read_dir, sessions_dir)
  if not ok then
    return entries
  end
  for _, path in ipairs(paths) do
    local name = path:match("([^/]+)$")
    if name then
      table.insert(entries, { label = name, id = path })
    end
  end
  return entries
end

local schema = {
  sessionizer.AllActiveWorkspaces {},
  sesh_sessions_generator,
}

function M.get_action()
  return sessionizer.show(schema)
end

function M.setup(_config) end

return M
