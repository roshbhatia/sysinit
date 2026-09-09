local wezterm = require("wezterm")

local M = {}

function M.json(argv, argument)
  if type(argv) ~= "table" or #argv == 0 then
    return nil, "No command configured"
  end
  local args = {}
  for _, value in ipairs(argv) do
    args[#args + 1] = value
  end
  if argument ~= nil then
    args[#args + 1] = argument
  end
  local ran, success, stdout, stderr = pcall(wezterm.run_child_process, args)
  if not ran then
    return nil, tostring(success)
  end
  if not success then
    return nil, stderr ~= "" and stderr or "Command failed"
  end
  local parsed, document = pcall(wezterm.json_parse, stdout)
  if not parsed or type(document) ~= "table" then
    return nil, "Command returned invalid JSON"
  end
  return document
end

return M
