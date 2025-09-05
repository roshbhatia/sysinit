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
    enabled = get_env_bool("SYSINIT_AGENTS_ENABLED", true) and get_env_bool("SYSINIT_COPILOT_ENABLED", true),
    "zbirenbaum/copilot.lua",
    lazy = false,
    config = function()
      require("copilot").setup({
        panel = {
          auto_refresh = false,
        },
        suggestion = {
          enabled = false,
          auto_trigger = false,
        },
      })
    end,
  },
}

return M
