local wezterm = require("wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

local M = {}

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

-- Lazily build and return the sessionizer action so plugin fetches happen on first keypress,
-- not at module load time (which would break all keybindings if the plugin isn't cached yet).
function M.get_action()
  local sessionizer = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer.wezterm")

  local function prefix(kind)
    return sessionizer.for_each_entry(function(entry)
      entry.label = kind .. "  " .. entry.label
    end)
  end

  local schema = {
    -- default workspace
    {
      sessionizer.DefaultWorkspace({}),
      processing = prefix("[default]"),
    },
    -- active workspaces
    {
      sessionizer.AllActiveWorkspaces({}),
      processing = prefix("[active] "),
    },
    -- sesh-managed sessions
    {
      sesh_sessions_generator,
      processing = prefix("[sesh]  "),
    },
  }

  return sessionizer.show(schema)
end

function M.get_ssh_picker_action()
  local hosts = {}
  -- Enumerate hosts from ~/.ssh/config
  for _, host in ipairs(wezterm.enumerate_ssh_hosts()) do
    -- Filter out wildcard entries or other non-host identifiers
    if not host:match("[*?]") then
      table.insert(hosts, { label = host, id = host })
    end
  end

  return wezterm.action.InputSelector({
    title = "SSH Connect",
    choices = hosts,
    fuzzy = true,
    action = wezterm.action_callback(function(window, pane, id, label)
      if id then
        -- Switch to a workspace named after the host
        window:perform_action(wezterm.action.SwitchToWorkspace({ name = id }), pane)
        -- Spawn standard ssh command in a new tab
        window:perform_action(
          wezterm.action.SpawnCommandInNewTab({
            args = { "ssh", id },
          }),
          pane
        )
      end
    end),
  })
end

function M.setup(_config)
  resurrect.state_manager.set_max_nlines(500)

  resurrect.state_manager.periodic_save({
    interval_seconds = 300,
    save_workspaces = true,
    save_windows = true,
    save_tabs = false,
  })

  wezterm.on("gui-startup", resurrect.state_manager.resurrect_on_gui_startup)
end

return M
