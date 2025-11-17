local function load_theme_config()
  local config_path = os.getenv("HOME") .. "/.config/sketchybar/theme_config.json"
  local file = io.open(config_path, "r")
  if not file then
    return {}
  end
  local content = file:read("*all")
  file:close()

  local cjson = require("cjson")
  local success, result = pcall(function()
    return cjson.decode(content)
  end)

  if success and result then
    return result
  else
    return {}
  end
end

local theme_config = load_theme_config()
local monospace_font = (
  theme_config.font
  and type(theme_config.font) == "table"
  and theme_config.font.monospace
) or "TX-02"

return {
  fonts = {
    text = {
      regular = { family = monospace_font, style = "Regular", size = 13.0 },
      bold = { family = monospace_font, style = "Bold", size = 13.0 },
    },
    icons = {
      regular = { family = "Symbols Nerd Font Mono", style = "Regular", size = 14.0 },
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
