local M = {}

local sbar = require("sketchybar")
local theme = require("sysinit.pkg.theme")
local settings = require("sysinit.pkg.config.settings")

local menu_watcher = sbar.add("item", {
  drawing = false,
  updates = false,
})

local space_menu_swap = sbar.add("item", {
  drawing = false,
  updates = true,
})

sbar.add("event", "swap_menus_and_spaces")

local max_items = 15
local menu_items = {}

for i = 1, max_items, 1 do
  local menu = sbar.add("item", "menu." .. i, {
    padding_left = settings.paddings,
    padding_right = settings.paddings,
    drawing = false,
    icon = { drawing = false },
    label = {
      font = {
        family = theme.fonts.text:match("([^:]+)"),
        style = settings.font.style_map[i == 1 and "Bold" or "Semibold"],
      },
      padding_left = 6,
      padding_right = 6,
    },
    click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s " .. i,
  })

  menu_items[i] = menu
end

sbar.add("bracket", { "/menu\\..*/" }, {
  background = { color = theme.colors.bg1 },
})

local menu_padding = sbar.add("item", "menu.padding", {
  drawing = false,
  width = 5,
})

local function update_menus(env)
  sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -l", function(menus)
    sbar.set("/menu\\..*/", { drawing = false })
    menu_padding:set({ drawing = true })
    id = 1
    for menu in string.gmatch(menus, "[^\r\n]+") do
      if id < max_items then
        menu_items[id]:set({ label = menu, drawing = true })
      else
        break
      end
      id = id + 1
    end
  end)
end

function M.setup()
  menu_watcher:subscribe("front_app_switched", update_menus)

  space_menu_swap:subscribe("swap_menus_and_spaces", function(env)
    local drawing = menu_items[1]:query().geometry.drawing == "on"
    if drawing then
      menu_watcher:set({ updates = false })
      sbar.set("/menu\\..*/", { drawing = false })
      sbar.set("/space\\..*/", { drawing = true })
      sbar.set("front_app", { drawing = true })
    else
      menu_watcher:set({ updates = true })
      sbar.set("/space\\..*/", { drawing = false })
      sbar.set("front_app", { drawing = false })
      update_menus()
    end
  end)
end

return M
