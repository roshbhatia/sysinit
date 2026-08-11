local M = {}

local ORDER = {
  "claudecode",
  "opencode",
  "amp",
  "pi",
  "codex",
  "copilot",
  "crush",
  "cursor",
  "devin",
  "antigravity",
  "goose",
  "hermes",
}

---@return table[]
function M.get_all()
  local adapters = {}
  for _, name in ipairs(ORDER) do
    local ok, adapter = pcall(require, "harness.adapters." .. name)
    if ok then
      table.insert(adapters, adapter)
    end
  end
  return adapters
end

---@return table[]
function M.get_all_available()
  local out = {}
  for _, adapter in ipairs(M.get_all()) do
    local ok, available = pcall(adapter.available)
    if ok and available then
      table.insert(out, adapter)
    end
  end
  return out
end

---@param name string
---@return table|nil
function M.get_by_name(name)
  if not name or name == "" then
    return nil
  end
  for _, adapter in ipairs(M.get_all()) do
    if adapter.name == name then
      return adapter
    end
  end
  return nil
end

return M
