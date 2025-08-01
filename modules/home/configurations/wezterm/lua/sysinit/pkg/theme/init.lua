local wezterm = require("wezterm")
local json_loader = require("sysinit.pkg.utils.json_loader")
local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))
local M = {}

local function get_window_appearance_config()
  local opacity = theme_config.transparency.enable and theme_config.transparency.opacity or 1.0
  local blur = theme_config.transparency.enable and 80 or 0
  local theme_name = theme_config.theme_name

  return {
    window_background_opacity = opacity,
    macos_window_background_blur = blur,
    color_scheme = theme_name,
  }
end

function M.setup(config)
  local configs = {
    get_window_appearance_config(),
  }

  for _, cfg in ipairs(configs) do
    for key, value in pairs(cfg) do
      config[key] = value
    end
  end
end

return M
