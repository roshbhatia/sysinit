local json_loader = require("sysinit.pkg.utils.json_loader")
local M = {}

local theme_config = nil

local function loadThemeConfig()
  if not theme_config then
    theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))
  end
  return theme_config
end

local function hexToRGBA(hex, alpha)
  alpha = alpha or 1.0
  hex = hex:gsub("#", "")

  local r = tonumber("0x" .. hex:sub(1, 2)) / 255
  local g = tonumber("0x" .. hex:sub(3, 4)) / 255
  local b = tonumber("0x" .. hex:sub(5, 6)) / 255

  return { red = r, green = g, blue = b, alpha = alpha }
end

function M.getColors()
  local config = loadThemeConfig()
  if not config then
    -- Fallback colors if theme config is not available
    return {
      background = { red = 0.1, green = 0.1, blue = 0.1, alpha = 0.9 },
      backgroundSecondary = { red = 0.15, green = 0.15, blue = 0.15, alpha = 0.8 },
      foreground = { red = 0.9, green = 0.9, blue = 0.9, alpha = 1.0 },
      primary = { red = 0.4, green = 0.6, blue = 1.0, alpha = 1.0 },
      accent = { red = 0.8, green = 0.5, blue = 0.0, alpha = 0.8 },
      muted = { red = 0.6, green = 0.6, blue = 0.6, alpha = 0.7 },
      overlay = { red = 0.2, green = 0.2, blue = 0.2, alpha = 0.3 },
    }
  end

  local transparency = config.transparency or { enable = true, opacity = 0.85 }
  local baseOpacity = transparency.enable and transparency.opacity or 1.0

  return {
    background = hexToRGBA(config.palette.bg_primary, baseOpacity * 0.9),
    backgroundSecondary = hexToRGBA(config.palette.bg_secondary, baseOpacity * 0.8),
    backgroundTertiary = hexToRGBA(config.palette.bg_tertiary, baseOpacity * 0.7),
    foreground = hexToRGBA(config.palette.fg_primary, 1.0),
    foregroundMuted = hexToRGBA(config.palette.fg_muted, 0.7),
    primary = hexToRGBA(config.palette.primary, 1.0),
    accent = hexToRGBA(config.palette.accent, 0.8),
    overlay = hexToRGBA(config.palette.bg_overlay, 0.3),
    border = hexToRGBA(config.palette.bg_overlay, 0.6),
    borderMuted = hexToRGBA(config.palette.bg_overlay, 0.3),
  }
end

function M.getWindowSwitcherPrefs()
  local colors = M.getColors()
  return {
    showThumbnails = true,
    showTitles = false,
    showSelectedTitle = false,
    showSelectedThumbnail = false,
    backgroundColor = colors.background,
    highlightColor = colors.primary,
  }
end

function M.getWorkspaceOverlayStyle()
  local colors = M.getColors()
  return {
    background = colors.overlay,
    border = colors.border,
    borderMuted = colors.borderMuted,
    text = colors.foreground,
  }
end

return M
