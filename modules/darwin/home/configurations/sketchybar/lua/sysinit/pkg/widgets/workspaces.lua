local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

local M = {}

local spaces = {}

local function make_label(workspace, is_focused)
  return {
    string = is_focused and "{" .. workspace .. "}" or workspace,
    color = is_focused and colors.syntax_builtin or colors.foreground_primary,
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

    sbar.add("item", "workspace_left_sep", {
      position = "center",
      icon = {
        string = "|",
        font = settings.fonts.separators.bold,
        color = colors.white,
      },
      background = { drawing = false },
      label = { drawing = false },
      padding_left = settings.spacing.separator_spacing,
      padding_right = settings.spacing.separator_spacing,
    })

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
          sbar.animate("circ", 10, function()
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

    sbar.add("item", "workspace_right_sep", {
      position = "center",
      icon = {
        string = "|",
        font = settings.fonts.separators.bold,
        color = colors.white,
      },
      background = { drawing = false },
      label = { drawing = false },
      padding_left = settings.spacing.separator_spacing,
      padding_right = settings.spacing.separator_spacing,
    })

    sbar.exec("aerospace list-workspaces --focused", function(focused_output, initial_exit_code)
      if initial_exit_code == 0 then
        local focused_workspace = focused_output:gsub("%s+", "")

        for ws, space_item in pairs(spaces) do
          local is_focused = (ws == focused_workspace)
          local label_config = make_label(ws, is_focused)
          if is_focused then
            sbar.animate("circ", 10, function()
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
