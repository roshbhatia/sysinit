local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")
local utils = require("sysinit.pkg.utils")
local cjson = require("cjson")
local config = require("sysinit.pkg.config")

local M = {}

local spaces = {}
local rift_cli = config.rift_cli_bin or "rift-cli"

local function make_label(workspace, is_focused)
  return {
    string = is_focused and "{" .. workspace .. "}" or workspace,
    color = is_focused and colors.workspace_focused or colors.foreground_primary,
    font = settings.fonts.text.regular,
  }
end

function M.setup()
  sbar.exec(rift_cli .. " query workspaces", function(workspaces_output, exit_code)
    if exit_code ~= 0 then
      return
    end

    local ok, workspace_group = pcall(cjson.decode, workspaces_output)
    if not ok or type(workspace_group) ~= "table" then
      return
    end
    for _, workspace in ipairs(workspace_group) do
      if
        type(workspace.name) ~= "string"
        or type(workspace.index) ~= "number"
        or type(workspace.is_focused) ~= "boolean"
      then
        return
      end
    end

    sbar.add("event", "rift_workspace_changed")

    utils.separator("workspace_left_sep", "center")

    for _, workspace in ipairs(workspace_group) do
      local name = workspace.name
      local index = workspace.index
      local item_name = "space." .. name

      local space = sbar.add("item", item_name, {
        position = "center",
        icon = { drawing = false },
        label = make_label(name, workspace.is_focused),
        background = { drawing = false },
        padding_left = settings.spacing.widget_spacing,
        padding_right = settings.spacing.widget_spacing,
        click_script = string.format("%s execute workspace switch %d", rift_cli, index),
      })

      space:subscribe("rift_workspace_changed", function(env)
        local focused_workspace = env.FOCUSED
        local is_focused = (name == focused_workspace)
        local label_config = make_label(name, is_focused)

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

      spaces[name] = space
    end

    utils.separator("workspace_right_sep", "center")

    for _, workspace in ipairs(workspace_group) do
      local space_item = spaces[workspace.name]
      local is_focused = workspace.is_focused
      local label_config = make_label(workspace.name, is_focused)
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
  end)
end

return M
