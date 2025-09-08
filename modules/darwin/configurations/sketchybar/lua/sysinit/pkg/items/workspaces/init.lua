local M = {}

local sbar = require("sketchybar")
local theme = require("sysinit.pkg.theme")

local function update_workspace(workspace)
  sbar.exec("aerospace list-workspaces --focused", function(focused, exit_code)
    if exit_code ~= 0 then return end
    
    local is_active = focused:gsub("%s+", "") == workspace
    local space_item = sbar.add("item", "space." .. workspace)
    
    if is_active then
      sbar.animate("tanh", 20, function()
        space_item:set({
          background = {
            color = theme.colors.accent,
            height = theme.geometry.workspace.height_active
          },
          label = {
            color = theme.colors.white,
            font = theme.fonts.text_bold
          }
        })
      end)
    else
      sbar.animate("tanh", 20, function()
        space_item:set({
          background = {
            color = theme.colors.item_bg,
            height = theme.geometry.workspace.height_inactive
          },
          label = {
            color = theme.colors.muted,
            font = theme.fonts.text_medium
          }
        })
      end)
    end
  end)
end

function M.setup()
  sbar.exec("aerospace list-workspaces --all", function(workspaces, exit_code)
    if exit_code ~= 0 then return end
    
    for workspace in workspaces:gmatch("%S+") do
      local space = sbar.add("item", "space." .. workspace, {
        position = "left",
        icon = { drawing = false },
        label = { 
          string = workspace,
          font = theme.fonts.text_bold
        },
        background = {
          corner_radius = theme.geometry.workspace.corner_radius,
          height = theme.geometry.workspace.height_inactive
        },
        padding_left = theme.geometry.workspace.padding,
        padding_right = theme.geometry.workspace.padding,
        click_script = "aerospace workspace " .. workspace
      })
      
      space:subscribe("aerospace_workspace_change", function(env)
        update_workspace(workspace)
      end)
      
      update_workspace(workspace)
    end
  end)

  local separator = sbar.add("item", "separator", {
    position = "left",
    icon = { 
      string = "|",
      color = theme.colors.muted,
      font = theme.fonts.text_medium
    },
    background = { drawing = false },
    padding_left = 6,
    padding_right = 6
  })
end

return M