local function load_theme_config()
  local config_path = os.getenv("HOME") .. "/.config/sketchybar/theme_config.json"
  local file = io.open(config_path, "r")
  if not file then
    return {}
  end
  local content = file:read("*all")
  file:close()
  return require("json").decode(content) or {}
end

local theme_config = load_theme_config()
local monospace_font = (theme_config.font and theme_config.font.monospace) or "TX-02"
local nerdfont_fallback = (theme_config.font and theme_config.font.nerdfontFallback)
  or "Symbols Nerd Font Mono"

return {
  fonts = {
    text = {
      regular = { family = monospace_font, style = "Regular", size = 13.0 },
      bold = { family = monospace_font, style = "Bold", size = 13.0 },
    },
    icons = {
      regular = { family = nerdfont_fallback, style = "Regular", size = 14.0 },
      small = { family = nerdfont_fallback, style = "Regular", size = 12.0 },
    },
    separators = {
      bold = { family = monospace_font, style = "Bold", size = 18.0 },
    },
  },

  spacing = {
    paddings = 3,
    widget_spacing = 6,
    section_spacing = 10,
    separator_spacing = 10,
  },
}
