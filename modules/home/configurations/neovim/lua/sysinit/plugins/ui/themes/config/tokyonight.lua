local styles = require("sysinit.plugins.ui.themes.styles")

local function convert_styles_for_tokyonight()
  -- TokyoNight only supports these style keys
  local supported_keys = {
    comments = true,
    keywords = true,
    functions = true,
    variables = true,
    sidebars = true,
    floats = true,
  }

  local converted = {}
  for k, v in pairs(styles) do
    if supported_keys[k] then
      if type(v) == "table" and #v > 0 then
        converted[k] = {}
        for _, style in ipairs(v) do
          converted[k][style] = true
        end
      elseif type(v) == "table" and #v == 0 then
        converted[k] = {}
      else
        converted[k] = v
      end
    end
  end
  return converted
end

return function(theme_config)
  return {
    style = theme_config.variant,
    transparent = true,
    terminal_colors = true,
    styles = convert_styles_for_tokyonight(),
  }
end
