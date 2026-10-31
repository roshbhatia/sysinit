local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")
local utils = require("sysinit.pkg.utils")
local config = require("sysinit.pkg.config")
local cjson = require("cjson")

local M = {}

local spaces = {}
local komorebic = config.komorebic_bin or "komorebic"
local workspace_names = { "1", "2", "3", "C", "M" }

local function make_label(workspace, is_focused)
  return {
    string = is_focused and "{" .. workspace .. "}" or workspace,
    color = is_focused and colors.workspace_focused or colors.foreground_primary,
    font = settings.fonts.text.regular,
  }
end

function M.setup()
  local function refresh()
    sbar.exec(komorebic .. " state", function(state_output, exit_code)
      if exit_code ~= 0 then
        return
      end
      local ok, state = pcall(cjson.decode, state_output)
      if not ok or type(state) ~= "table" then
        return
      end

      local monitors = state.monitors and state.monitors.elements
      local focused_monitor = state.monitors and state.monitors.focused
      local monitor = monitors and monitors[focused_monitor + 1]
      local workspaces = monitor and monitor.workspaces
      local elements = workspaces and workspaces.elements
      local focused_index = workspaces and workspaces.focused
      local focused_workspace = elements and elements[focused_index + 1]
      if not focused_workspace then
        return
      end
      focused_workspace = focused_workspace.name

      for name, item in pairs(spaces) do
        local is_focused = name == focused_workspace
        item:set({
          label = make_label(name, is_focused),
          icon = { highlight = is_focused },
        })
      end
    end)
  end

  utils.separator("workspace_left_sep", "center")
  for index, workspace in ipairs(workspace_names) do
    spaces[workspace] = sbar.add("item", "space." .. workspace, {
      position = "center",
      icon = { drawing = false },
      label = make_label(workspace, false),
      background = { drawing = false },
      padding_left = settings.spacing.widget_spacing,
      padding_right = settings.spacing.widget_spacing,
      click_script = string.format("%s focus-workspaces %d", komorebic, index - 1),
    })
  end
  utils.separator("workspace_right_sep", "center")

  local updater = sbar.add("item", "komorebi_workspace_updater", {
    position = "center",
    drawing = false,
    update_freq = 1,
  })
  updater:subscribe("routine", refresh)
  updater:subscribe("komorebi_workspace_change", refresh)
  refresh()
end

return M
