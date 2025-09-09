local M = {}

-- Simple JSON decoder
local function decode_json_string(str)
  -- Handle basic JSON string value
  return str:gsub('^"', ''):gsub('"$', '')
end

local function hex_to_number(hex_str)
  -- Convert #rrggbb to 0xffrrggbb
  if hex_str:match("^#[%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F]$") then
    return tonumber("0xff" .. hex_str:sub(2))
  end
  return 0xff000000
end

local function read_theme_config()
  local home_dir = os.getenv("HOME") or "/Users/" .. os.getenv("USER")
  local config_path = home_dir .. "/.config/sketchybar/theme_config.json"

  local file = io.open(config_path, "r")
  if not file then
    -- Fallback theme if config file doesn't exist
    return {
      colors = {
        bar_bg = 0x40000000,
        bg1 = 0xff2e3440,
        bg2 = 0xff3b4252,
        white = 0xffd8dee9,
        grey = 0xff81a1c1,
        black = 0xff2e3440,
        red = 0xffbf616a,
        green = 0xffa3be8c,
        blue = 0xff5e81ac,
        yellow = 0xffebcb8b,
        orange = 0xffd08770,
        accent = 0xff88c0d0,
        popup_bg = 0xff3b4252,
      },
      geometry = {
        bar = {
          height = 32,
          corner_radius = 0,
          margin = 10,
          y_offset = 0,
          padding = 10,
        },
      },
      icons = {
        apple = "",
        volume = {
          _0 = "󰸈",
          _10 = "󰕿",
          _33 = "󰖀",
          _66 = "󰖀",
          _100 = "󰕾",
        },
      },
    }
  end

  local content = file:read("*all")
  file:close()

  -- Extract color values from semanticColors structure
  local colors = {}

  -- Extract semantic colors - background section
  local bg_match = content:match('"semanticColors"%s*:.*"background"%s*:%s*{([^}]+)}')
  if bg_match then
    for key, value in bg_match:gmatch('"([^"]+)"%s*:%s*"([^"]+)"') do
      if key == "primary" then
        colors.bar_bg = hex_to_number(value) & 0x80ffffff -- Add transparency for bar
        colors.popup_bg = hex_to_number(value)
        colors.black = hex_to_number(value)
      elseif key == "overlay" then
        colors.bg1 = hex_to_number(value)
      elseif key == "secondary" then
        colors.bg2 = hex_to_number(value)
      end
    end
  end

  -- Extract semantic colors - foreground section
  local fg_match = content:match('"semanticColors"%s*:.*"foreground"%s*:%s*{([^}]+)}')
  if fg_match then
    for key, value in fg_match:gmatch('"([^"]+)"%s*:%s*"([^"]+)"') do
      if key == "primary" then
        colors.white = hex_to_number(value)
      elseif key == "muted" then
        colors.grey = hex_to_number(value)
      end
    end
  end

  -- Extract semantic colors - accent section
  local accent_match = content:match('"semanticColors"%s*:.*"accent"%s*:%s*{([^}]+)}')
  if accent_match then
    for key, value in accent_match:gmatch('"([^"]+)"%s*:%s*"([^"]+)"') do
      if key == "primary" then
        colors.accent = hex_to_number(value)
        colors.blue = hex_to_number(value)
      end
    end
  end

  -- Extract semantic colors - semantic section (error, success, etc.)
  local semantic_match = content:match('"semanticColors"%s*:.*"semantic"%s*:%s*{([^}]+)}')
  if semantic_match then
    for key, value in semantic_match:gmatch('"([^"]+)"%s*:%s*"([^"]+)"') do
      if key == "error" then
        colors.red = hex_to_number(value)
      elseif key == "success" then
        colors.green = hex_to_number(value)
      elseif key == "warning" then
        colors.yellow = hex_to_number(value)
        colors.orange = hex_to_number(value)
      end
    end
  end

  -- Ensure we have all required colors with fallbacks
  colors.bar_bg = colors.bar_bg or 0x80000000
  colors.bg1 = colors.bg1 or 0xff2e3440
  colors.bg2 = colors.bg2 or 0xff3b4252
  colors.white = colors.white or 0xffffffff
  colors.grey = colors.grey or 0xff888888
  colors.black = colors.black or 0xff000000
  colors.red = colors.red or 0xffff0000
  colors.green = colors.green or 0xff00ff00
  colors.blue = colors.blue or 0xff0000ff
  colors.yellow = colors.yellow or 0xffffff00
  colors.orange = colors.orange or colors.yellow or 0xffff8800
  colors.accent = colors.accent or colors.blue or 0xff0088ff
  colors.popup_bg = colors.popup_bg or colors.bg1

  return {
    colors = colors,
    geometry = {
      bar = {
        height = 32,
        corner_radius = 0,
        margin = 10,
        y_offset = 0,
        padding = 10,
      },
    },
    icons = {
      apple = "󰀶",
      volume = {
        _0 = "󰸈",
        _10 = "󰕿",
        _33 = "󰖀",
        _66 = "󰖀",
        _100 = "󰕾",
      },
    },
  }
end

-- Load theme configuration
local theme_config = read_theme_config()

-- Export the theme
M.colors = theme_config.colors
M.geometry = theme_config.geometry
M.icons = theme_config.icons

return M
