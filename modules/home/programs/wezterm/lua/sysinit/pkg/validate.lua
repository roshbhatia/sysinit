local M = {}

function M.setup(config)
  local seen = {}
  for _, binding in ipairs(config.keys or {}) do
    local chord = tostring(binding.mods) .. "+" .. tostring(binding.key)
    if seen[chord] then
      error("duplicate key binding: " .. chord)
    end
    seen[chord] = true
  end
end

return M
