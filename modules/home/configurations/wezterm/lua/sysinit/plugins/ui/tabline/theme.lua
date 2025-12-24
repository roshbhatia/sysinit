local json_loader = require("sysinit.pkg.utils.json_loader")

local M = {}

local theme_config = nil
local colors = nil

function M.load()
  if not theme_config then
    theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))
  end

  if not colors then
    local p = theme_config.palette

    colors = {
      tab_bar_background = p.bg_primary,

      active_tab = {
        fg = p.bg_primary,
        bg = p.primary,
        underline = p.primary,
      },

      inactive_tab = {
        fg = p.fg_muted,
        bg = p.bg_secondary,
      },

      hover_tab = {
        fg = p.fg_primary,
        bg = p.bg_tertiary,
      },

      mode_normal = {
        fg = p.bg_primary,
        bg = p.primary,
      },

      mode_copy = {
        fg = p.bg_primary,
        bg = p.yellow,
      },

      mode_search = {
        fg = p.bg_primary,
        bg = p.green,
      },

      mode_other = {
        fg = p.bg_primary,
        bg = p.blue,
      },

      userhost = {
        fg = p.fg_secondary,
        bg = p.bg_secondary,
      },
    }
  end

  return colors
end

function M.get_tab_colors(state)
  local c = M.load()
  if state == "active" then
    return c.active_tab
  elseif state == "hover" then
    return c.hover_tab
  else
    return c.inactive_tab
  end
end

function M.get_mode_colors(mode)
  local c = M.load()
  local mode_lower = mode:lower()

  if mode_lower:find("copy") then
    return c.mode_copy
  elseif mode_lower:find("search") then
    return c.mode_search
  elseif mode_lower == "default" or mode_lower == "" then
    return c.mode_normal
  else
    return c.mode_other
  end
end

function M.get_userhost_colors()
  local c = M.load()
  return c.userhost
end

function M.get_background()
  local c = M.load()
  return c.tab_bar_background
end

return M
