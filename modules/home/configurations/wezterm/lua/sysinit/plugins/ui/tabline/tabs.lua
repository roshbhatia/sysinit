local wezterm = require("wezterm")
local theme = require("sysinit.plugins.ui.tabline.theme")

local M = {}

local function truncate(str, max_len)
  if #str <= max_len then
    return str
  end
  return str:sub(1, max_len - 1) .. "…"
end

local function get_tab_content(tab)
  local cwd_uri = tab.active_pane.current_working_dir
  if cwd_uri then
    local cwd_url = tostring(cwd_uri)
    local cwd_path = cwd_url:gsub("file://[^/]*/", "/")
    local basename = cwd_path:match("([^/]+)/?$")
    if basename and basename ~= "" then
      return basename
    end
  end

  local process = tab.active_pane.foreground_process_name
  if process then
    return process:match("([^/]+)$")
  end

  return "shell"
end

local function create_tab_format(index, content, state, colors)
  local left_bracket = state == "active" and "{" or "["
  local right_bracket = state == "active" and "}" or "]"

  local format = {
    { Foreground = { Color = colors.fg } },
    { Background = { Color = colors.bg } },
    { Text = left_bracket },
  }

  if state == "active" then
    table.insert(format, { Attribute = { Underline = "Single" } })
  end

  table.insert(format, { Text = index .. ":" .. content })

  if state == "active" then
    table.insert(format, { Attribute = { Underline = "None" } })
  end

  table.insert(format, { Text = right_bracket })

  return format
end

function M.format_tab_title(tab, tabs, panes, config, hover, max_width)
  local index = tab.tab_index + 1
  local content = get_tab_content(tab)

  content = truncate(content, 19)

  local state = "inactive"
  if tab.is_active then
    state = "active"
  elseif hover then
    state = "hover"
  end

  local colors = theme.get_tab_colors(state)

  local format = create_tab_format(index, content, state, colors)

  table.insert(format, { Background = { Color = theme.get_background() } })
  table.insert(format, { Foreground = { Color = theme.get_background() } })
  table.insert(format, { Text = " " })

  return format
end

return M
