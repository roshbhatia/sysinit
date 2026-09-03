local ui_format = require("sysinit.pkg.ui.format")

local M = {}

local function clean(value)
  if type(value) ~= "string" then
    return ""
  end
  return (value:gsub("[%c]", " "):gsub("%s+", " "):match("^%s*(.-)%s*$"))
end

local function basename(value)
  return clean(value):match("([^/\\]+)$") or ""
end

local function cwd(pane)
  local uri = pane and pane.current_working_dir
  if not uri then
    return ""
  end
  local value = uri.file_path or tostring(uri)
  return ui_format.smart_path(clean(value))
end

local function metadata(pane, process, session, directory)
  local vars = pane and pane.user_vars or {}
  local explicit = clean(vars.SYSINIT_WINDOW_METADATA)
  if explicit ~= "" then
    return explicit
  end

  local title = clean(pane and pane.title)
  if title == "" or title == "wezterm" or title == process or title == session or title == directory then
    return ""
  end
  if basename(title) == process then
    return ""
  end
  return title
end

function M.format(tab, pane, session)
  local active = (tab and tab.active_pane) or pane or {}
  local process = ui_format.normalize_proc(basename(active.foreground_process_name)) or ""
  local workspace = clean(session)
  local directory = cwd(active)
  local details = metadata(active, process, workspace, directory)
  local parts = {}

  for _, value in ipairs({ process, workspace, directory, details }) do
    if value ~= "" then
      parts[#parts + 1] = value
    end
  end

  return table.concat(parts, " · ")
end

return M
