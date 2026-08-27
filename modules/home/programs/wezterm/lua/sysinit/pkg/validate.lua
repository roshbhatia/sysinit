local M = {}

local modifier_aliases = {
  CMD = "SUPER",
  WIN = "SUPER",
}

local function canonical_modifiers(modifiers)
  local parts = {}
  for part in tostring(modifiers or "NONE"):gmatch("[^|]+") do
    parts[#parts + 1] = modifier_aliases[part] or part
  end
  table.sort(parts)
  return table.concat(parts, "|")
end

function M.setup(config)
  local seen = {}
  for _, binding in ipairs(config.keys or {}) do
    local chord = canonical_modifiers(binding.mods) .. "+" .. tostring(binding.key)
    if seen[chord] then
      error("duplicate key binding: " .. chord)
    end
    seen[chord] = true
  end
end

return M
