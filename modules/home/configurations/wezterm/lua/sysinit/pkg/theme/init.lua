local wezterm = require("wezterm")
local json_loader = require("sysinit.pkg.utils.json_loader")
local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))
local M = {}

local function is_nvim_running()
  local pane = wezterm.mux.get_active_pane()
  if not pane then
    return false
  end

  local proc = pane:get_foreground_process_name()
  if proc then
    local basename = proc:match("([^/]+)$")
    if basename and (basename:match("^n?vim$") or basename:match("^n?vim%.")) then
      return true
    end
  end
  return false
end

local function get_effective_transparency()
  if theme_config.nvim_transparency_override and is_nvim_running() then
    return theme_config.nvim_transparency_override
  end
  return theme_config.transparency
end

local function get_window_appearance_config()
  local transparency = get_effective_transparency()
  local opacity = nil
  if transparency.enable then
    opacity = transparency.opacity or 0.85
  end
  local blur = transparency.enable and 80 or 0
  local theme_name = theme_config.theme_name

  local config = {
    macos_window_background_blur = blur,
    color_scheme = theme_name,
    colors = {
      foreground = theme_config.palette.fg_primary,
      background = theme_config.palette.bg_primary,
      cursor_bg = theme_config.palette.primary,
      cursor_fg = theme_config.palette.bg_primary,
      cursor_border = theme_config.palette.primary,
      selection_fg = theme_config.palette.bg_primary,
      selection_bg = theme_config.palette.primary,
      scrollbar_thumb = theme_config.palette.bg_overlay,
      split = theme_config.palette.bg_overlay,
      ansi = {
        theme_config.ansi["0"],
        theme_config.ansi["1"],
        theme_config.ansi["2"],
        theme_config.ansi["3"],
        theme_config.ansi["4"],
        theme_config.ansi["5"],
        theme_config.ansi["6"],
        theme_config.ansi["7"],
      },
      brights = {
        theme_config.ansi["8"],
        theme_config.ansi["9"],
        theme_config.ansi["10"],
        theme_config.ansi["11"],
        theme_config.ansi["12"],
        theme_config.ansi["13"],
        theme_config.ansi["14"],
        theme_config.ansi["15"],
      },
      tab_bar = {
        background = theme_config.palette.bg_primary,
        active_tab = {
          bg_color = theme_config.palette.primary,
          fg_color = theme_config.palette.bg_primary,
        },
        inactive_tab = {
          bg_color = theme_config.palette.bg_secondary,
          fg_color = theme_config.palette.fg_muted,
        },
        inactive_tab_hover = {
          bg_color = theme_config.palette.bg_tertiary,
          fg_color = theme_config.palette.fg_primary,
        },
        new_tab = {
          bg_color = theme_config.palette.bg_secondary,
          fg_color = theme_config.palette.fg_muted,
        },
        new_tab_hover = {
          bg_color = theme_config.palette.bg_tertiary,
          fg_color = theme_config.palette.fg_primary,
        },
      },
    },
  }

  if opacity then
    config.window_background_opacity = opacity
  end

  return config
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

      if transparency.enable then
        overrides.window_background_opacity = transparency.opacity or 0.85
      else
        overrides.window_background_opacity = nil
      end
      overrides.macos_window_background_blur = transparency.enable and 80 or 0

      window:set_config_overrides(overrides)
    end)

    wezterm.on("update-status", function(window, pane)
      local overrides = window:get_config_overrides() or {}
      local transparency = get_effective_transparency()

      local new_opacity = nil
      if transparency.enable then
        new_opacity = transparency.opacity or 0.85
      end
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
