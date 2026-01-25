local config = require("sysinit.pkg.config")

local opacity = config.transparency.opacity
local blur = config.transparency.blur
local alpha = string.format("0x%02x", math.floor(opacity * 255))

local function color(hex, custom_alpha)
  local prefix = custom_alpha or "0xff"
  return prefix .. hex:sub(2)
end

local colors = {
  -- Foreground
  foreground_primary = color(config.semanticColors.foreground.primary),
  foreground_muted = color(config.semanticColors.foreground.muted),

  -- Background
  background_primary = color(config.semanticColors.background.primary, alpha),
  background_secondary = color(config.semanticColors.background.secondary, alpha),

  -- Accent
  accent_primary = color(config.semanticColors.accent.primary),

  -- Semantic
  semantic_error = color(config.semanticColors.semantic.error),
  semantic_success = color(config.semanticColors.semantic.success),
  semantic_warning = color(config.semanticColors.semantic.warning),

  -- Syntax
  syntax_builtin = color(config.semanticColors.syntax.builtin),
  syntax_function = color(config.semanticColors.syntax["function"]),
  syntax_keyword = color(config.semanticColors.syntax.keyword),
  syntax_string = color(config.semanticColors.syntax.string),
  syntax_type = color(config.semanticColors.syntax.type),
  syntax_variable = color(config.semanticColors.syntax.variable),
  syntax_comment = color(config.semanticColors.syntax.comment),
  syntax_constant = color(config.semanticColors.syntax.constant),
  syntax_number = color(config.semanticColors.syntax.number),
  syntax_operator = color(config.semanticColors.syntax.operator),

  -- Blur
  blur_radius = blur,
}

-- Popup colors
colors.popup = {
  bg = colors.background_primary,
  border = colors.accent_primary,
}

-- Convenience aliases
colors.white = colors.foreground_primary
colors.bg = colors.background_primary

return colors
