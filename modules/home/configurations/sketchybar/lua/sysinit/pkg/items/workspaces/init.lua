local M = {}

local sbar = require("sketchybar")
local theme = require("sysinit.pkg.theme")

local spaces = {}

local function update_workspaces()
  sbar.exec("aerospace list-workspaces --focused", function(focused, exit_code)
    if exit_code ~= 0 then
      return
    end

    local focused_workspace = focused:gsub("%s+", "")

    for workspace, space_item in pairs(spaces) do
      local is_active = workspace == focused_workspace

      if is_active then
        space_item:set({
          label = {
            string = "[" .. workspace .. "]",
            color = theme.colors.white,
            font = theme.fonts.text_bold,
          },
        })
      else
        space_item:set({
          label = {
            string = " " .. workspace .. " ",
            color = theme.colors.muted,
            font = theme.fonts.text_medium,
          },
        })
      end
    end
  end)
end

function M.setup()
  sbar.exec("aerospace list-workspaces --all", function(workspaces, exit_code)
    if exit_code ~= 0 then
      return
    end

    for workspace in workspaces:gmatch("%S+") do
      local space = sbar.add("item", "space." .. workspace, {
        position = "left",
        icon = { drawing = false },
        label = {
          string = " " .. workspace .. " ",
          font = theme.fonts.text_medium,
          color = theme.colors.muted,
        },
        background = { drawing = false },
        padding_left = 2,
        padding_right = 2,
        click_script = "aerospace workspace " .. workspace,
      })

      -- Store reference to the space item
      spaces[workspace] = space

      space:subscribe("aerospace_workspace_change", function(env)
        update_workspaces()
      end)
    end

    -- Initial update
    update_workspaces()
  end)

  local separator = sbar.add("item", "separator", {
    position = "left",
    icon = {
      string = "│",
      color = theme.colors.muted,
      font = theme.fonts.text_medium,
    },
    background = { drawing = false },
    padding_left = 8,
    padding_right = 8,
  })
end

return M
