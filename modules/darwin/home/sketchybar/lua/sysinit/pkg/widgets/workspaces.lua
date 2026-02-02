local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")
local utils = require("sysinit.pkg.utils")

local M = {}

local spaces = {}

local function make_label(workspace, is_focused)
  return {
    string = is_focused and "{" .. workspace .. "}" or workspace,
    color = is_focused and colors.workspace_focused or colors.foreground_primary,
    font = is_focused and settings.fonts.text.bold or settings.fonts.text.regular,
  }
end

function M.setup()
  sbar.exec("aerospace list-workspaces --all", function(workspaces_output, exit_code)
    if exit_code ~= 0 then
      return
    end

    local workspace_group = {}
    for workspace in workspaces_output:gmatch("%S+") do
      table.insert(workspace_group, workspace)
    end

    sbar.add("event", "aerospace_workspace_change")

    utils.separator("workspace_left_sep", "center")

    for _, workspace in ipairs(workspace_group) do
      local item_name = "space." .. workspace

      local space = sbar.add("item", item_name, {
        position = "center",
        icon = { drawing = false },
        label = make_label(workspace, false),
        background = { drawing = false },
        padding_left = settings.spacing.widget_spacing,
        padding_right = settings.spacing.widget_spacing,
        click_script = string.format("aerospace workspace %s", workspace),
      })

      space:subscribe("aerospace_workspace_change", function(env)
        local focused_workspace = env.FOCUSED
        local is_focused = (workspace == focused_workspace)
        local label_config = make_label(workspace, is_focused)

        if is_focused then
          utils.animate(function()
            space:set({
              label = label_config,
              icon = { highlight = true },
            })
          end)
        else
          space:set({
            label = label_config,
            icon = { highlight = false },
          })
        end
      end)

      spaces[workspace] = space
    end

    utils.separator("workspace_right_sep", "center")

    sbar.exec("aerospace list-workspaces --focused", function(focused_output, initial_exit_code)
      if initial_exit_code == 0 then
        local focused_workspace = utils.trim(focused_output)

        for ws, space_item in pairs(spaces) do
          local is_focused = (ws == focused_workspace)
          local label_config = make_label(ws, is_focused)
          if is_focused then
            utils.animate(function()
              space_item:set({
                label = label_config,
                icon = { highlight = true },
              })
            end)
          else
            space_item:set({
              label = label_config,
              icon = { highlight = false },
            })
          end
        end
      end
    end)
  end)
end

return M
