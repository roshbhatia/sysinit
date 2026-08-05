local M = {}

---@return string|nil
function M.get_active()
  local v = vim.g.harness_active
  if v == nil or v == "" then
    return nil
  end
  return v
end

---@param name string
function M.set_active(name)
  vim.g.harness_active = name
  pcall(function()
    require("harness.file_refresh").start()
  end)
end

function M.clear_active()
  vim.g.harness_active = nil
  pcall(function()
    require("harness.file_refresh").stop()
  end)
end

return M
