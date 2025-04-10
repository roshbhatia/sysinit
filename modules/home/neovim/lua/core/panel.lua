local M = {}

-- Panel types
M.PANELS = {
  LEFT = "left",
  RIGHT = "right",
  MIDDLE = "middle",
}

M.panel_plugins = {
  [M.PANELS.LEFT] = {},
  [M.PANELS.RIGHT] = {},
  [M.PANELS.MIDDLE] = {},
}

-- Enhanced plugin registration with optional configuration
function M.register_panel_plugin(panel_type, plugin_spec, opts)
  if not M.panel_plugins[panel_type] then
    error("Invalid panel type: " .. tostring(panel_type))
  end
  
  -- Add optional configuration for panel behavior
  plugin_spec.panel_opts = opts or {
    width_percent = 20,  -- Default 20% width
    position = "start",  -- Default to start of panel
    priority = 100,      -- Default priority
  }
  
  table.insert(M.panel_plugins[panel_type], plugin_spec)
end

-- Retrieve panel plugins with optional filtering
function M.get_panel_plugins(panel_type, filter_fn)
  local plugins = M.panel_plugins[panel_type] or {}
  
  if filter_fn and type(filter_fn) == "function" then
    return vim.tbl_filter(filter_fn, plugins)
  end
  
  return plugins
end

-- Get a specific panel's primary plugin
function M.get_primary_panel_plugin(panel_type)
  local plugins = M.get_panel_plugins(panel_type)
  
  -- Sort by priority if multiple plugins exist
  table.sort(plugins, function(a, b)
    local a_priority = a.panel_opts and a.panel_opts.priority or 100
    local b_priority = b.panel_opts and b.panel_opts.priority or 100
    return a_priority > b_priority
  end)
  
  return plugins[1]
end

-- Toggle a specific panel
function M.toggle_panel(panel_type)
  local primary_plugin = M.get_primary_panel_plugin(panel_type)
  
  if primary_plugin and primary_plugin.toggle then
    primary_plugin.toggle()
  else
    vim.notify("No toggleable plugin found for " .. panel_type .. " panel", vim.log.levels.WARN)
  end
end

return M
