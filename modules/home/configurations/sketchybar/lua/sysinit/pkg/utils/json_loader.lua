local M = {}

function M.get_config_path(filename)
  local xdg_config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
  return xdg_config_home .. "/sketchybar/" .. filename
end

function M.load_json_file(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return {}
  end

  local content = file:read("*all")
  file:close()

  if content == "" then
    return {}
  end

  local success, result = pcall(function()
    return require("cjson").decode(content)
  end)

  if success then
    return result
  else
    return {}
  end
end

return M
