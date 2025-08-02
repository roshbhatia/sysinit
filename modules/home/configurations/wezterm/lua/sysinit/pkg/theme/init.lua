local wezterm = require("wezterm")
local json_loader = require("sysinit.pkg.utils.json_loader")
local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))
local M = {}

local function is_nvim_running()
  -- Check if any pane is running nvim/vim
  local tab = wezterm.mux.get_active_tab()
  if not tab then
    return false
  end

  for _, pane in ipairs(tab:panes()) do
    local proc = pane:get_foreground_process_name()
    if proc then
      local basename = proc:match("([^/]+)$")
      if basename and (basename:match("^n?vim$") or basename:match("^n?vim%.")) then
        return true
      end
    end
  end
  return false
end

local function get_effective_transparency()
  -- Check if nvim override exists and nvim is running
  if theme_config.nvim_transparency_override and is_nvim_running() then
    return theme_config.nvim_transparency_override
  end
  return theme_config.transparency
end

local function get_window_appearance_config()
  local transparency = get_effective_transparency()
  local opacity = transparency.enable and transparency.opacity or 1.0
  local blur = transparency.enable and 80 or 0
  local theme_name = theme_config.theme_name

  return {
    window_background_opacity = opacity,
    macos_window_background_blur = blur,
    color_scheme = theme_name,
  }
end

function M.setup(config)
  -- Set initial theme config
  local configs = {
    get_window_appearance_config(),
  }

  for _, cfg in ipairs(configs) do
    for key, value in pairs(cfg) do
      config[key] = value
    end
  end

  -- Add event handler to update transparency when process changes
  if theme_config.nvim_transparency_override then
    config.window_decorations = "RESIZE"

    wezterm.on("window-config-reloaded", function(window, pane)
      local overrides = window:get_config_overrides() or {}
      local transparency = get_effective_transparency()

      overrides.window_background_opacity = transparency.enable and transparency.opacity or 1.0
      overrides.macos_window_background_blur = transparency.enable and 80 or 0

      window:set_config_overrides(overrides)
    end)

    wezterm.on("update-status", function(window, pane)
      local overrides = window:get_config_overrides() or {}
      local transparency = get_effective_transparency()

      local new_opacity = transparency.enable and transparency.opacity or 1.0
      local new_blur = transparency.enable and 80 or 0

      if overrides.window_background_opacity ~= new_opacity then
        overrides.window_background_opacity = new_opacity
        overrides.macos_window_background_blur = new_blur
        window:set_config_overrides(overrides)
      end
    end)
  end
end

return M
