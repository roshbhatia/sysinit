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
  local home_dir = os.getenv("HOME")
  if not home_dir then
    local username = os.getenv("USER")
    home_dir = "/Users/" .. username
  end
  return home_dir .. "/.config/wezterm/" .. filename
end

return M
