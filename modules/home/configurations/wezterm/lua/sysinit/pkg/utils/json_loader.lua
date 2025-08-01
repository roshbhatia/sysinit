local M = {}

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
  local username = os.getenv("USER")
  local home_dir = "/Users/" .. username
  return home_dir .. "/.config/wezterm/" .. filename
end

return M
