local M = {}

function M.load_json_file(filepath, global_var_name)
  local file = io.open(filepath, "r")
  if not file then
    error("Could not open file: " .. filepath)
  end

  local content = file:read("*all")
  file:close()

  local success, data = pcall(vim.json.decode, content)
  if not success then
    error("Failed to parse JSON from: " .. filepath .. "\nError: " .. tostring(data))
  end

  if global_var_name ~= nil then
    vim.g[global_var_name] = data
  end

  return data
end

function M.get_config_path(filename)
  return vim.fn.stdpath("config") .. "/" .. filename
end

return M

