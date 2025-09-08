local M = {}

local json_loader = require("sysinit.pkg.utils.json_loader")
local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))

local function hex_to_sketchybar(hex)
  if not hex or hex == "" then return "0xffffffff" end
  if hex:sub(1, 1) == "#" then
    hex = hex:sub(2)
  end
  return "0xff" .. hex
end

local function alpha_hex_to_sketchybar(alpha, hex)
  if not hex or hex == "" then return "0x40000000" end
  if hex:sub(1, 1) == "#" then
    hex = hex:sub(2)
  end
  return "0x" .. alpha .. hex
end

M.colors = {
  white = hex_to_sketchybar(theme_config.semantic_colors and theme_config.semantic_colors.foreground and theme_config.semantic_colors.foreground.primary or "#ffffff"),
  muted = hex_to_sketchybar(theme_config.semantic_colors and theme_config.semantic_colors.foreground and theme_config.semantic_colors.foreground.muted or "#9ca0a4"),
  accent = hex_to_sketchybar(theme_config.semantic_colors and theme_config.semantic_colors.accent and theme_config.semantic_colors.accent.primary or "#89b4fa"),
  bar_bg = alpha_hex_to_sketchybar("40", "000000"),
  item_bg = alpha_hex_to_sketchybar("33", "000000"),
  popup_bg = alpha_hex_to_sketchybar("ee", theme_config.semantic_colors and theme_config.semantic_colors.background and theme_config.semantic_colors.background.secondary or "#ff5722")
}

M.fonts = {
  app_icon = "sketchybar-app-font:Regular:14.0",
  text = "TX-02:Semibold:12.0",
  text_medium = "TX-02:Medium:12.0",
  text_bold = "TX-02:Bold:13.0"
}

M.geometry = {
  bar = {
    height = 34,
    corner_radius = 16,
    margin = 8,
    y_offset = 6,
    padding = 12
  },
  item = {
    height = 26,
    corner_radius = 8,
    padding = 2
  },
  workspace = {
    height_active = 24,
    height_inactive = 22,
    corner_radius = 6,
    padding = 8
  }
}

return M