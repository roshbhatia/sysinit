local M = {}

local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

local spaces = {}

local function make_label(workspace, is_focused)
  return {
    string = " " .. workspace .. " ",
    color = is_focused and colors.white or colors.grey,
    font = is_focused and settings.fonts.text.bold or settings.fonts.text.normal,
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

    for workspace in workspaces_output:gmatch("%S+") do
      local item_name = "space." .. workspace
      local space = sbar.add("item", item_name, {
        position = "left",
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

    sbar.subscribe("aerospace_workspace_change", update_focused_workspace)

    update_focused_workspace()
  end)

  sbar.add("item", "separator", {
    position = "left",
    icon = {
      string = "│",
      font = settings.fonts.separators.normal,
      color = colors.grey,
    },
    background = { drawing = false },
    label = { drawing = false },
    padding_left = settings.spacing.separator_spacing,
    padding_right = settings.spacing.separator_spacing,
  })
end

return M
