local M = {}

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

  -- Simple JSON parser for our theme config
  local theme = {}

  -- Extract colors from JSON
  local colors_match = content:match('"colors"%s*:%s*{([^}]+)}')
  if colors_match then
    theme.colors = {}
    for key, value in colors_match:gmatch('"([^"]+)"%s*:%s*"?([^",]+)"?') do
      -- Convert hex colors to numbers
      if value:match("^#[%da-fA-F]+$") then
        theme.colors[key] = tonumber(value:gsub("#", "0xff"))
      elseif value:match("^0x[%da-fA-F]+$") then
        theme.colors[key] = tonumber(value)
      else
        theme.colors[key] = value
      end
    end
  end

  -- Extract other config sections if needed
  theme.geometry = theme.geometry or {
    bar = {
      height = 32,
      corner_radius = 0,
      margin = 10,
      y_offset = 0,
      padding = 10,
    },
  }

  theme.icons = theme.icons or {
    apple = "",
    volume = {
      _0 = "󰸈",
      _10 = "󰕿",
      _33 = "󰖀",
      _66 = "󰖀",
      _100 = "󰕾",
    },
  }

  return theme
end

-- Load theme configuration
local theme_config = read_theme_config()

-- Export the theme
M.colors = theme_config.colors
M.geometry = theme_config.geometry
M.icons = theme_config.icons

return M
