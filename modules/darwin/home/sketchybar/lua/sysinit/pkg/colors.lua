local config = require("sysinit.pkg.config")

local opacity = config.transparency.opacity
local blur = config.transparency.blur
local alpha = string.format("0x%02x", math.floor(opacity * 255))

local function color(hex, custom_alpha)
  local prefix = custom_alpha or "0xff"
  return prefix .. hex:sub(2)
end

local colors = {
  base00 = color(config.base16.base00),
  base01 = color(config.base16.base01),
  base02 = color(config.base16.base02),
  base03 = color(config.base16.base03),
  base04 = color(config.base16.base04),
  base05 = color(config.base16.base05),
  base06 = color(config.base16.base06),
  base07 = color(config.base16.base07),
  base08 = color(config.base16.base08),
  base09 = color(config.base16.base09),
  base0A = color(config.base16.base0A),
  base0B = color(config.base16.base0B),
  base0C = color(config.base16.base0C),
  base0D = color(config.base16.base0D),
  base0E = color(config.base16.base0E),
  base0F = color(config.base16.base0F),

  foreground_primary = color(config.base16.base05),
  foreground_muted = color(config.base16.base03),

  background_primary = color(config.base16.base00, alpha),
  background_secondary = color(config.base16.base01, alpha),

  accent_primary = color(config.base16.base0D),

  semantic_error = color(config.base16.base08),
  semantic_success = color(config.base16.base0B),
  semantic_warning = color(config.base16.base0A),

  syntax_builtin = color(config.base16.base0C),
  syntax_function = color(config.base16.base0D),
  syntax_keyword = color(config.base16.base0E),
  syntax_string = color(config.base16.base0B),
  syntax_type = color(config.base16.base0A),
  syntax_variable = color(config.base16.base08),
  syntax_comment = color(config.base16.base03),
  syntax_constant = color(config.base16.base09),
  syntax_number = color(config.base16.base09),
  syntax_operator = color(config.base16.base05),

  blur_radius = blur,
}

colors.popup = {
  bg = colors.background_primary,
  border = colors.base0D,
}

colors.white = colors.foreground_primary
colors.bg = colors.background_primary
colors.workspace_focused = colors.base08

return colors
