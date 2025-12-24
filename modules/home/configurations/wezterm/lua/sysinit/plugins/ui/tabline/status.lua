local wezterm = require("wezterm")
local theme = require("sysinit.plugins.ui.tabline.theme")

local M = {}

local function get_mode(window)
  local mode = window:active_key_table()
  if not mode or mode == "" then
    return "default"
  end
  return mode
end

local function get_username()
  local username = os.getenv("USER") or os.getenv("USERNAME") or "unknown"
  return username
end

local function get_hostname()
  local hostname = wezterm.hostname() or "localhost"
  return hostname:match("^([^%.]+)") or hostname
end

local function format_mode(mode, colors)
  local mode_upper = mode:upper()
  if mode == "default" then
    mode_upper = "NORMAL"
  end

  return wezterm.format({
    { Foreground = { Color = colors.fg } },
    { Background = { Color = colors.bg } },
    { Attribute = { Intensity = "Bold" } },
    { Text = " [" .. mode_upper .. "] " },
  })
end

local function format_userhost(colors)
  local username = get_username()
  local hostname = get_hostname()
  local userhost = username .. "@" .. hostname

  return wezterm.format({
    { Foreground = { Color = colors.fg } },
    { Background = { Color = colors.bg } },
    { Text = " [" .. userhost .. "] " },
  })
end

function M.update_status(window, pane)
  local mode = get_mode(window)
  local mode_colors = theme.get_mode_colors(mode)
  local userhost_colors = theme.get_userhost_colors()
  local bg = theme.get_background()

  local mode_str = format_mode(mode, mode_colors)
  local userhost_str = format_userhost(userhost_colors)

  window:set_left_status("")

  local right_status = wezterm.format({
    { Background = { Color = bg } },
    { Text = " " },
  }) .. mode_str .. wezterm.format({
    { Background = { Color = bg } },
    { Text = "  " },
  }) .. userhost_str

  window:set_right_status(right_status)
end

return M
