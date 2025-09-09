local M = {}

local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

local spaces = {}

function M.setup()
  sbar.exec("aerospace list-workspaces --all", function(workspaces_output, exit_code)
    if exit_code ~= 0 then
      return
    end

    for workspace in workspaces_output:gmatch("%S+") do
      local space = sbar.add("item", "space." .. workspace, {
        position = "left",
        icon = { drawing = false },
        label = {
          string = " " .. workspace .. " ",
          color = colors.grey,
          font = {
            family = settings.font,
            style = "Medium",
            size = 13.0,
          },
        },
        background = { drawing = false },
        padding_left = 2,
        padding_right = 2,
        click_script = "aerospace workspace "
          .. workspace
          .. "; sketchybar --trigger aerospace_workspace_change",
      })

      spaces[workspace] = space

      space:subscribe("aerospace_workspace_change", function(env)
        sbar.exec("aerospace list-workspaces --focused", function(focused, exit_code)
          if exit_code ~= 0 then
            return
          end

          local focused_workspace = focused:gsub("%s+", "")
          local selected = workspace == focused_workspace

          if selected then
            space:set({
              label = {
                string = "[" .. workspace .. "]",
                color = colors.white,
                font = {
                  family = settings.font,
                  style = "Bold",
                  size = 13.0,
                },
              },
            })
          else
            space:set({
              label = {
                string = " " .. workspace .. " ",
                color = colors.grey,
                font = {
                  family = settings.font,
                  style = "Light",
                  size = 13.0,
                },
              },
            })
          end
        end)
      end)
    end

    sbar.exec("aerospace list-workspaces --focused", function(focused_output)
      local focused_workspace = focused_output:gsub("%s+", "")
      if spaces[focused_workspace] then
        spaces[focused_workspace]:set({
          label = {
            string = "[" .. focused_workspace .. "]",
            color = colors.white,
            font = {
              family = settings.font,
              style = "Bold",
              size = 13.0,
            },
          },
        })
      end
    end)
  end)

  local separator = sbar.add("item", "separator", {
    position = "left",
    icon = {
      string = "│",
      color = colors.grey,
      font = {
        family = settings.font,
        style = "Regular",
        size = 12.0,
      },
    },
    background = { drawing = false },
    label = { drawing = false },
    padding_left = 8,
    padding_right = 8,
  })
end

return M
