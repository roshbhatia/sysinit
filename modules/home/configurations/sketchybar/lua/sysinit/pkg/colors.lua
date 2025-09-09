local function load_json()
  local config_path = os.getenv("HOME") .. "/.config/sketchybar/theme_config.json"
  local file = io.open(config_path, "r")
  if not file then
    return {}
  end

  local content = file:read("*all")
  file:close()

  local cjson = require("cjson")
  local theme = cjson.decode(content)

  local colors = {}

  colors.white = "0xff" .. (theme.semanticColors.foreground.primary or "#ffffff"):sub(2)
  colors.grey = "0xff" .. (theme.semanticColors.foreground.muted or "#888888"):sub(2)
  colors.bg = "0xff" .. (theme.semanticColors.background.primary or "#000000"):sub(2)
  colors.bar_bg = "0xff" .. (theme.semanticColors.accent.primary or "#0088ff"):sub(2)
  colors.accent = "0xff" .. (theme.semanticColors.accent.primary or "#0088ff"):sub(2)
  colors.red = "0xff" .. (theme.semanticColors.semantic.error or "#ff0000"):sub(2)
  colors.green = "0xff" .. (theme.semanticColors.semantic.success or "#00ff00"):sub(2)
  colors.yellow = "0xff" .. (theme.semanticColors.semantic.warning or "#ffff00"):sub(2)
  colors.blue = "0xff" .. (theme.palette.blue or "#3e8fb0"):sub(2)
  colors.orange = "0xff" .. (theme.palette.orange or "#ea9a97"):sub(2)

  colors.popup = {
    bg = colors.bg,
    border = colors.accent,
  }

  return colors
end

return load_json()
