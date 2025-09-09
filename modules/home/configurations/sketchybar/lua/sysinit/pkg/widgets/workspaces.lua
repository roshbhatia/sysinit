local M = {}

local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

local spaces = {}

local function make_label(workspace, is_focused, is_prev)
  local workspace_text
  if is_focused then
    workspace_text = "[" .. workspace .. "]"
  elseif is_prev then
    workspace_text = "(" .. workspace .. ")"
  else
    workspace_text = workspace
  end

  local color = colors.white
  if is_focused then
    color = colors.green
  elseif is_prev then
    color = colors.red
  end

  return {
    string = workspace_text,
    color = color,
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

      -- Add workspace-specific event
      sbar.add("event", "aerospace_workspace_change_" .. workspace)

      local space = sbar.add("item", item_name, {
        position = "center",
        icon = { drawing = false },
        label = make_label(workspace, false, false),
        background = { drawing = false },
        padding_left = settings.spacing.widget_spacing,
        padding_right = settings.spacing.widget_spacing,
        click_script = string.format("aerospace workspace %s", workspace),
      })

      -- Subscribe to workspace-specific event for optimized updates
      space:subscribe("aerospace_workspace_change_" .. workspace, function(env)
        local focused_workspace = env.FOCUSED_WORKSPACE
        local prev_workspace = env.PREV_WORKSPACE

        local is_focused = (workspace == focused_workspace)
        local is_prev = (workspace == prev_workspace)

        local label_config = make_label(workspace, is_focused, is_prev)
        space:set({
          label = label_config,
          icon = { drawing = false },
        })
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

    -- Initial focused workspace detection
    sbar.exec("aerospace list-workspaces --focused", function(focused_output, initial_exit_code)
      if initial_exit_code == 0 then
        local focused_workspace = focused_output:gsub("%s+", "")

        -- Update initial state
        for ws, space_item in pairs(spaces) do
          local is_focused = (ws == focused_workspace)
          local label_config = make_label(ws, is_focused, false)
          space_item:set({
            label = label_config,
            icon = { drawing = false },
          })
        end
      end
    end)
  end)
end

return M
