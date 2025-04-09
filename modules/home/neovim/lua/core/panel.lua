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

function M.register_panel_plugin(panel_type, plugin_spec)
  if not M.panel_plugins[panel_type] then
    error("Invalid panel type: " .. panel_type)
  end
  table.insert(M.panel_plugins[panel_type], plugin_spec)
end

function M.get_panel_plugins(panel_type)
  return M.panel_plugins[panel_type] or {}
end

return M
