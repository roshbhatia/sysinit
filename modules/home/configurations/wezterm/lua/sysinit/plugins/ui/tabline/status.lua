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
    mode_upper = "INSERT"
  elseif mode:lower():find("copy") then
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
  local mode_colors = theme.get_mode_colors()
  local userhost_colors = theme.get_userhost_colors()
  local bg = theme.get_background()

  local mode_str = format_mode(mode, mode_colors)
  local userhost_str = format_userhost(userhost_colors)

  local tab_info = ""
  local tabs = window:mux_window():tabs_with_info()
  for _, item in ipairs(tabs) do
    local tab = item.tab
    local tab_index = tab:tab_id()
    tab_info = tab_info .. "[" .. tab_index .. "] "
  end

  local screen_width = window:active_pane():get_dimensions().cols
  local mode_width = #mode + 4
  local userhost_width = #get_username() + #get_hostname() + 5
  local tab_width = #tab_info

  local left_space = math.floor((screen_width - mode_width - userhost_width - tab_width) / 2)
  local padding_str = string.rep(" ", math.max(0, left_space))

  window:set_left_status("")

  local right_status = padding_str
    .. mode_str
    .. wezterm.format({
      { Background = { Color = bg } },
      { Text = "  " },
    })
    .. userhost_str

  window:set_right_status(right_status)
end

return M
