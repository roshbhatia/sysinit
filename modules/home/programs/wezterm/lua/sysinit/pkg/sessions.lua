local wezterm = require("wezterm")
local plugin_loader = require("sysinit.pkg.plugin_loader")

local M = {}

local function sy_sessions_generator()
  local sessions_dir = wezterm.home_dir .. "/.local/state/seshy/sessions"
  local entries = {}
  local ok, paths = pcall(wezterm.read_dir, sessions_dir)
  if not ok then
    return entries
  end
  for _, path in ipairs(paths) do
    local name = path:match("([^/]+)$")
    if name then
      local success, stdout, _ = wezterm.run_child_process({ "sy", "path", name })
      local id = (success and stdout) and stdout:gsub("%s+$", "") or path
      table.insert(entries, { label = name, id = id })
    end
  end
  return entries
end

local function zoxide_generator()
  local entries = {}
  local success, stdout, _ = wezterm.run_child_process({ "zoxide", "query", "-l" })
  if not success or not stdout then
    return entries
  end
  for line in stdout:gmatch("[^\n]+") do
    local dir = line:gsub("^%s+", ""):gsub("%s+$", "")
    if dir ~= "" then
      local label = dir:gsub(wezterm.home_dir, "~")
      table.insert(entries, { label = label, id = dir })
    end
  end
  return entries
end

function M.get_action()
  local sess_ok, sessionizer = plugin_loader.load("sessionizer")
  if not sess_ok then
    wezterm.log_warn("Failed to load sessionizer: " .. tostring(sessionizer))
    return wezterm.action.Nop
  end

  local function prefix(kind)
    return sessionizer.for_each_entry(function(entry)
      entry.label = kind .. "  " .. entry.label
    end)
  end

  local schema = {
    {
      sessionizer.DefaultWorkspace({}),
      processing = prefix("[default]"),
    },
    {
      sessionizer.AllActiveWorkspaces({}),
      processing = prefix("[active] "),
    },
    {
      sy_sessions_generator,
      processing = prefix("[sy]    "),
    },
    {
      zoxide_generator,
      processing = prefix("[dir]   "),
    },
  }

  return sessionizer.show(schema)
end

function M.get_ssh_picker_action()
  local hosts = {}

  for host, _ in pairs(wezterm.enumerate_ssh_hosts()) do
    local is_wildcard = host:match("[*?]")
    local is_github = host:lower():match("github")

    if not is_wildcard and not is_github then
      table.insert(hosts, { label = host, id = host })
    end
  end

  table.sort(hosts, function(a, b)
    return a.label < b.label
  end)

  return wezterm.action.InputSelector({
    title = "Select host:",
    choices = hosts,
    fuzzy = true,
    action = wezterm.action_callback(function(window, pane, id, label)
      if id then
        window:perform_action(wezterm.action.SpawnTab({ DomainName = "SSH:" .. id }), pane)
      end
    end),
  })
end

function M.setup(_config)
  local ok, resurrect = plugin_loader.load("resurrect")
  if not ok then
    wezterm.log_warn("Failed to load resurrect.wezterm: " .. tostring(resurrect))
    return
  end

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
