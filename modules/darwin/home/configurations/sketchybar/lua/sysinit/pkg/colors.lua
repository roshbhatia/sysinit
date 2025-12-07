local function load_json()
  local config_path = os.getenv("HOME") .. "/.config/sketchybar/theme_config.json"
  local file = io.open(config_path, "r")
  if not file then
    return {}
  end

  local content = file:read("*all")
  file:close()

  local cjson = require("cjson")
  local theme = cjson.decode(content)

  local fallbacks = {
    foreground_primary = "#ffffff",
    foreground_muted = "#888888",
    background_primary = "#000000",
    accent_primary = "#0088ff",
    semantic_error = "#ff0000",
    semantic_success = "#00ff00",
    semantic_warning = "#ffff00",
    syntax_builtin = "#eb6f92",
    syntax_function = "#3e8fb0",
    syntax_keyword = "#c4a7e7",
    syntax_string = "#3e8fb0",
    syntax_type = "#f6c177",
    syntax_variable = "#e0def4",
    syntax_comment = "#6e6a86",
    syntax_constant = "#ea9a97",
    syntax_number = "#ea9a97",
    syntax_operator = "#9ccfd8",
  }

  local function safeColor(path, fallback_key, alpha)
    local prefix = alpha or "0xff"
    local color = path or fallbacks[fallback_key]
    return prefix .. color:sub(2)
  end

  local opacity = theme.transparency and theme.transparency.opacity or 0.85
  local alpha = string.format("0x%02x", math.floor(opacity * 255))
  local colors = {}

  colors.foreground_primary =
    safeColor(theme.semanticColors.foreground.primary, "foreground_primary")
  colors.foreground_muted = safeColor(theme.semanticColors.foreground.muted, "foreground_muted")
  colors.background_primary =
    safeColor(theme.semanticColors.background.primary, "background_primary", alpha)
  colors.background_secondary =
    safeColor(theme.semanticColors.background.secondary, "background_primary", alpha)
  colors.accent_primary = safeColor(theme.semanticColors.accent.primary, "accent_primary")
  colors.semantic_error = safeColor(theme.semanticColors.semantic.error, "semantic_error")
  colors.semantic_success = safeColor(theme.semanticColors.semantic.success, "semantic_success")
  colors.semantic_warning = safeColor(theme.semanticColors.semantic.warning, "semantic_warning")
  colors.syntax_builtin = safeColor(theme.semanticColors.syntax.builtin, "syntax_builtin")
  colors.syntax_function = safeColor(theme.semanticColors.syntax["function"], "syntax_function")
  colors.syntax_keyword = safeColor(theme.semanticColors.syntax.keyword, "syntax_keyword")
  colors.syntax_string = safeColor(theme.semanticColors.syntax.string, "syntax_string")
  colors.syntax_type = safeColor(theme.semanticColors.syntax.type, "syntax_type")
  colors.syntax_variable = safeColor(theme.semanticColors.syntax.variable, "syntax_variable")
  colors.syntax_comment = safeColor(theme.semanticColors.syntax.comment, "syntax_comment")
  colors.syntax_constant = safeColor(theme.semanticColors.syntax.constant, "syntax_constant")
  colors.syntax_number = safeColor(theme.semanticColors.syntax.number, "syntax_number")
  colors.syntax_operator = safeColor(theme.semanticColors.syntax.operator, "syntax_operator")

  colors.popup = {
    bg = colors.background_primary,
    border = colors.accent_primary,
  }

  return colors
end

return load_json()
