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
end

function M.clear_active()
  vim.g.harness_active = nil
end

return M
