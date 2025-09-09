local M = {}

local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

local spaces = {}

local function make_label(workspace, is_focused)
  local workspace_text = is_focused and ("[" .. workspace .. "]") or (" " .. workspace .. " ")
  return {
    string = workspace_text,
    color = is_focused and colors.white or colors.grey,
    font = is_focused and { family = "TX-02", style = "Bold", size = 13.0 } or { family = "TX-02", style = "Regular", size = 13.0 },
  }
end

local function update_focused_workspace()
  sbar.exec("aerospace list-workspaces --focused", function(focused_output, exit_code)
    if exit_code ~= 0 then
      return
    end

    local focused_workspace = focused_output:gsub("%s+", "")
    for workspace, space_item in pairs(spaces) do
      local is_focused = (workspace == focused_workspace)
      space_item:set({ label = make_label(workspace, is_focused) })
    end
  end)
end

function M.setup()
  sbar.exec("aerospace list-workspaces --all", function(workspaces_output, exit_code)
    if exit_code ~= 0 then
      return
    end

    -- Create workspace group for proper centering
    local workspace_group = {}

    for workspace in workspaces_output:gmatch("%S+") do
      table.insert(workspace_group, workspace)
    end

    -- Add left separator
    sbar.add("item", "workspace_left_sep", {
      position = "center",
      icon = {
        string = "|",
        font = { family = "TX-02", style = "Bold", size = 18.0 },
        color = colors.white,
      },
      background = { drawing = false },
      label = { drawing = false },
      padding_left = settings.spacing.separator_spacing,
      padding_right = settings.spacing.separator_spacing,
    })

    -- Add workspaces
    for _, workspace in ipairs(workspace_group) do
      local item_name = "space." .. workspace
      local space = sbar.add("item", item_name, {
        position = "center",
        icon = { drawing = false },
        label = make_label(workspace, false),
        background = { drawing = false },
        padding_left = settings.spacing.widget_spacing,
        padding_right = settings.spacing.widget_spacing,
        click_script = string.format(
          "aerospace workspace %s; sketchybar --trigger aerospace_workspace_change",
          workspace
        ),
      })

      spaces[workspace] = space
    end

    -- Add right separator
    sbar.add("item", "workspace_right_sep", {
      position = "center",
      icon = {
        string = "|",
        font = { family = "TX-02", style = "Bold", size = 18.0 },
        color = colors.white,
      },
      background = { drawing = false },
      label = { drawing = false },
      padding_left = settings.spacing.separator_spacing,
      padding_right = settings.spacing.separator_spacing,
    })

    sbar.subscribe("aerospace_workspace_change", update_focused_workspace)
    update_focused_workspace()
  end)
end

return M
