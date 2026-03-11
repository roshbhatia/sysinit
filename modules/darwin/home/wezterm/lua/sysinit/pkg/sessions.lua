local wezterm = require("wezterm")

local M = {}

local sessionizer = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer.wezterm")
local zoxide = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer-zoxide.git")

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

local function prefix(kind)
  return sessionizer.for_each_entry(function(entry)
    entry.label = kind .. "  " .. entry.label
  end)
end

local schema = {
  -- default workspace
  {
    sessionizer.DefaultWorkspace {},
    processing = prefix("[default]"),
  },
  -- active workspaces
  {
    sessionizer.AllActiveWorkspaces {},
    processing = prefix("[active] "),
  },
  -- sesh-managed sessions
  {
    sesh_sessions_generator,
    processing = prefix("[sesh]  "),
  },
  -- zoxide frecency directories
  {
    zoxide.Zoxide {},
    processing = {
      sessionizer.for_each_entry(function(entry)
        entry.label = entry.label:gsub(wezterm.home_dir, "~")
      end),
      prefix("[zoxide] "),
    },
  },
}

function M.get_action()
  return sessionizer.show(schema)
end

function M.setup(_config) end

return M
