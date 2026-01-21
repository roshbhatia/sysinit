local M = {}

function M.is_linux()
  local handle = io.popen("uname -s 2>/dev/null")
  if not handle then
    return false
  end
  local result = handle:read("*a")
  handle:close()
  return result:match("Linux") ~= nil
end

function M.is_darwin()
  local handle = io.popen("uname -s 2>/dev/null")
  if not handle then
    return false
  end
  local result = handle:read("*a")
  handle:close()
  return result:match("Darwin") ~= nil
end

-- Get current username with empty string fallback
function M.get_username()
  return os.getenv("USER") or ""
end

-- Get home directory with fallback to /Users/{username}
function M.get_home_dir()
  local home = os.getenv("HOME")
  if home then
    return home
  end
  return "/Users/" .. M.get_username()
end

-- Get nix user bin directory
function M.get_nix_user_bin()
  return "/etc/profiles/per-user/" .. M.get_username() .. "/bin"
end

-- Get nix binary path for a specific binary
function M.get_nix_binary(name)
  return M.get_nix_user_bin() .. "/" .. name
end

-- Extract process name from pane (returns just the executable name)
function M.get_process_name(pane)
  local proc = pane:get_foreground_process_name()
  if not proc then
    return nil
  end
  return proc:match("([^/\\]+)$")
end

function M.load_json_file(filepath)
  local file = io.open(filepath, "r")
  if not file then
    error("Could not open file: " .. filepath)
  end

  local content = file:read("*all")
  file:close()

  local wezterm = require("wezterm")
  local success, data = pcall(wezterm.json_parse, content)

  if not success then
    error("Failed to parse JSON from: " .. filepath .. "\nError: " .. tostring(data))
  end

  return data
end

function M.get_config_path(filename)
  return M.get_home_dir() .. "/.config/wezterm/" .. filename
end

return M
