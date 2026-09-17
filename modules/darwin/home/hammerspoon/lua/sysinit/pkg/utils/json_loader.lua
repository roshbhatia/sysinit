local M = {}

function M.get_config_path(filename)
  local home = os.getenv("HOME")
  local root = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
  return root .. "/sysinit/" .. filename
end

function M.load_json_file(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return nil
  end

  local content = file:read("*all")
  file:close()

  if not content or content == "" then
    return nil
  end

  if not hs or not hs.json then
    return nil
  end
  local ok, result = pcall(hs.json.decode, content)
  if ok and type(result) == "table" then
    return result
  end
  return nil
end

return M
