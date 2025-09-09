-- Load theme colors from JSON using simple Lua JSON parser
local function load_json()
  local config_path = os.getenv("HOME") .. "/.config/sketchybar/theme_config.json"
  local file = io.open(config_path, "r")
  if not file then
    return {}
  end

  local content = file:read("*all")
  file:close()

  -- Simple JSON extraction for semanticColors
  local colors = {}

  -- Extract primary foreground (white text)
  local white = content:match('"foreground"[^}]*"primary":%s*"([^"]*)"')
  colors.white = white and ("0xff" .. white:sub(2)) or "0xffffffff"

  -- Extract muted foreground (grey text)
  local grey = content:match('"foreground"[^}]*"muted":%s*"([^"]*)"')
  colors.grey = grey and ("0xff" .. grey:sub(2)) or "0xff888888"

  -- Extract primary background
  local bg = content:match('"background"[^}]*"primary":%s*"([^"]*)"')
  colors.bg = bg and ("0xff" .. bg:sub(2)) or "0xff000000"
  colors.bar_bg = bg and ("0x80" .. bg:sub(2)) or "0x80000000" -- with transparency

  -- Extract primary accent
  local accent = content:match('"accent"[^}]*"primary":%s*"([^"]*)"')
  colors.accent = accent and ("0xff" .. accent:sub(2)) or "0xff0088ff"

  -- Extract semantic colors
  local red = content:match('"semantic"[^}]*"error":%s*"([^"]*)"')
  colors.red = red and ("0xff" .. red:sub(2)) or "0xffff0000"

  local green = content:match('"semantic"[^}]*"success":%s*"([^"]*)"')
  colors.green = green and ("0xff" .. green:sub(2)) or "0xff00ff00"

  local yellow = content:match('"semantic"[^}]*"warning":%s*"([^"]*)"')
  colors.yellow = yellow and ("0xff" .. yellow:sub(2)) or "0xffffff00"

  -- Popup colors
  colors.popup = {
    bg = colors.bg,
    border = colors.accent,
  }

  return colors
end

return load_json()
