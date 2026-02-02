local config = require("sysinit.pkg.config")

local opacity = config.transparency.opacity
local blur = config.transparency.blur
local alpha = string.format("0x%02x", math.floor(opacity * 255))

local function color(hex, custom_alpha)
  local prefix = custom_alpha or "0xff"
  return prefix .. hex:sub(2)
end

local colors = {
  -- Base16 Palette (direct access)
  base00 = color(config.base16.base00),
  base01 = color(config.base16.base01),
  base02 = color(config.base16.base02),
  base03 = color(config.base16.base03),
  base04 = color(config.base16.base04),
  base05 = color(config.base16.base05),
  base06 = color(config.base16.base06),
  base07 = color(config.base16.base07),
  base08 = color(config.base16.base08), -- Red
  base09 = color(config.base16.base09), -- Orange
  base0A = color(config.base16.base0A), -- Yellow
  base0B = color(config.base16.base0B), -- Green
  base0C = color(config.base16.base0C), -- Cyan
  base0D = color(config.base16.base0D), -- Blue
  base0E = color(config.base16.base0E), -- Magenta
  base0F = color(config.base16.base0F), -- Brown

  -- Foreground (mapped to base16)
  foreground_primary = color(config.base16.base05), -- Normal text
  foreground_muted = color(config.base16.base03), -- Muted text / comments

  -- Background (mapped to base16 with transparency)
  background_primary = color(config.base16.base00, alpha), -- Primary background
  background_secondary = color(config.base16.base01, alpha), -- Secondary background

  -- Accent (mapped to base16)
  accent_primary = color(config.base16.base0D), -- Blue

  -- Semantic (mapped to base16)
  semantic_error = color(config.base16.base08), -- Red
  semantic_success = color(config.base16.base0B), -- Green
  semantic_warning = color(config.base16.base0A), -- Yellow

  -- Syntax (mapped to base16)
  syntax_builtin = color(config.base16.base0C), -- Cyan
  syntax_function = color(config.base16.base0D), -- Blue
  syntax_keyword = color(config.base16.base0E), -- Magenta
  syntax_string = color(config.base16.base0B), -- Green
  syntax_type = color(config.base16.base0A), -- Yellow
  syntax_variable = color(config.base16.base08), -- Red
  syntax_comment = color(config.base16.base03), -- Muted
  syntax_constant = color(config.base16.base09), -- Orange
  syntax_number = color(config.base16.base09), -- Orange
  syntax_operator = color(config.base16.base05), -- Normal text

  -- Blur
  blur_radius = blur,
}

-- Popup colors (use base16 directly)
colors.popup = {
  bg = colors.background_primary, -- base00 with alpha
  border = colors.base0D, -- Blue
}

-- Convenience aliases
colors.white = colors.foreground_primary
colors.bg = colors.background_primary
colors.workspace_focused = colors.base08 -- Red for focused workspace

return colors
