local M = {}

local sbar = require("sketchybar")
local theme = require("sysinit.pkg.theme")

-- Execute the event provider binary which provides the event "network_update"
-- for the network interface "en0", which is fired every 2.0 seconds.
sbar.exec("killall network_load >/dev/null; $CONFIG_DIR/helpers/event_providers/network_load/bin/network_load en0 network_update 2.0")

local popup_width = 250

local wifi_up = sbar.add("item", "widgets.wifi1", {
  position = "right",
  padding_left = -5,
  width = 0,
  icon = {
    padding_right = 0,
    font = {
      family = theme.fonts.system_icon:match("([^:]+)"),
      style = theme.fonts.style_map["Bold"],
      size = 9.0,
    },
    string = theme.icons.wifi.upload,
  },
  label = {
    font = {
      family = theme.fonts.numbers:match("([^:]+)"),
      style = theme.fonts.style_map["Bold"],
      size = 9.0,
    },
    color = theme.colors.red,
    string = "??? Bps",
  },
  y_offset = 4,
})

local wifi_down = sbar.add("item", "widgets.wifi2", {
  position = "right",
  padding_left = -5,
  icon = {
    padding_right = 0,
    font = {
      family = theme.fonts.system_icon:match("([^:]+)"),
      style = theme.fonts.style_map["Bold"],
      size = 9.0,
    },
    string = theme.icons.wifi.download,
  },
  label = {
    font = {
      family = theme.fonts.numbers:match("([^:]+)"),
      style = theme.fonts.style_map["Bold"],
      size = 9.0,
    },
    color = theme.colors.blue,
    string = "??? Bps",
  },
  y_offset = -4,
})

local wifi = sbar.add("item", "widgets.wifi.padding", {
  position = "right",
  label = { drawing = false },
})

-- Background around the item
local wifi_bracket = sbar.add("bracket", "widgets.wifi.bracket", {
  wifi.name,
  wifi_up.name,
  wifi_down.name
}, {
  background = { color = theme.colors.bg1 },
  popup = { align = "center", height = 30 }
})

local ssid = sbar.add("item", {
  position = "popup." .. wifi_bracket.name,
  icon = {
    font = {
      family = theme.fonts.text:match("([^:]+)"),
      style = theme.fonts.style_map["Bold"],
      size = tonumber(theme.fonts.text:match(":([^:]+):([%d.]+)$")) or 12,
    },
    string = theme.icons.wifi.router,
  },
  width = popup_width,
  align = "center",
  label = {
    font = {
      family = theme.fonts.text:match("([^:]+)"),
      size = 15,
      style = theme.fonts.style_map["Bold"]
    },
    max_chars = 18,
    string = "????????????",
  },
  background = {
    height = 2,
    color = theme.colors.grey,
    y_offset = -15
  }
})

local hostname = sbar.add("item", {
  position = "popup." .. wifi_bracket.name,
  icon = {
    align = "left",
    string = "Hostname:",
    width = popup_width / 2,
  },
  label = {
    max_chars = 20,
    string = "????????????",
    width = popup_width / 2,
    align = "right",
  }
})

local ip = sbar.add("item", {
  position = "popup." .. wifi_bracket.name,
  icon = {
    align = "left",
    string = "IP:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  }
})

local mask = sbar.add("item", {
  position = "popup." .. wifi_bracket.name,
  icon = {
    align = "left",
    string = "Subnet mask:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  }
})

local router = sbar.add("item", {
  position = "popup." .. wifi_bracket.name,
  icon = {
    align = "left",
    string = "Router:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  },
})

sbar.add("item", { position = "right", width = theme.geometry.group_paddings })

local function copy_label_to_clipboard(env)
  local label = sbar.query(env.NAME).label.value
  sbar.exec("echo \"" .. label .. "\" | pbcopy")
  sbar.set(env.NAME, { label = { string = theme.icons.clipboard, align="center" } })
  sbar.delay(1, function()
    sbar.set(env.NAME, { label = { string = label, align = "right" } })
  end)
end

local function hide_details()
  wifi_bracket:set({ popup = { drawing = false } })
end

local function toggle_details()
  local should_draw = wifi_bracket:query().popup.drawing == "off"
  if should_draw then
    wifi_bracket:set({ popup = { drawing = true }})
    sbar.exec("networksetup -getcomputername", function(result)
      hostname:set({ label = result })
    end)
    sbar.exec("ipconfig getifaddr en0", function(result)
      ip:set({ label = result })
    end)
    sbar.exec("ipconfig getsummary en0 | awk -F ' SSID : '  '/ SSID : / {print $2}'", function(result)
      ssid:set({ label = result })
    end)
    sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'", function(result)
      mask:set({ label = result })
    end)
    sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
      router:set({ label = result })
    end)
  else
    hide_details()
  end
end

function M.setup()
  wifi_up:subscribe("network_update", function(env)
    local up_color = (env.upload == "000 Bps") and theme.colors.grey or theme.colors.red
    local down_color = (env.download == "000 Bps") and theme.colors.grey or theme.colors.blue
    wifi_up:set({
      icon = { color = up_color },
      label = {
        string = env.upload,
        color = up_color
      }
    })
    wifi_down:set({
      icon = { color = down_color },
      label = {
        string = env.download,
        color = down_color
      }
    })
  end)

  wifi:subscribe({"wifi_change", "system_woke"}, function(env)
    sbar.exec("ipconfig getifaddr en0", function(ip)
      local connected = not (ip == "")
      wifi:set({
        icon = {
          string = connected and theme.icons.wifi.connected or theme.icons.wifi.disconnected,
          color = connected and theme.colors.white or theme.colors.red,
        },
      })
    end)
  end)

  wifi_up:subscribe("mouse.clicked", toggle_details)
  wifi_down:subscribe("mouse.clicked", toggle_details)
  wifi:subscribe("mouse.clicked", toggle_details)
  wifi:subscribe("mouse.exited.global", hide_details)

  ssid:subscribe("mouse.clicked", copy_label_to_clipboard)
  hostname:subscribe("mouse.clicked", copy_label_to_clipboard)
  ip:subscribe("mouse.clicked", copy_label_to_clipboard)
  mask:subscribe("mouse.clicked", copy_label_to_clipboard)
  router:subscribe("mouse.clicked", copy_label_to_clipboard)
end

return M
