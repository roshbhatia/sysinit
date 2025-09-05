local M = {}

local function get_env_bool(key, default)
  local value = vim.fn.getenv(key)
  if value == vim.NIL or value == "" then
    return default
  end
  return value:lower() == "true" or value == "1"
end

M.plugins = {
  {
    enabled = get_env_bool("SYSINIT_AGENTS_ENABLED", true)
      and get_env_bool("SYSINIT_COPILOT_ENABLED", true),
    "giuxtaposition/blink-cmp-copilot",
    dependencies = {
      "zbirenbaum/copilot.lua",
    },
    lazy = true,
  },
}

return M
