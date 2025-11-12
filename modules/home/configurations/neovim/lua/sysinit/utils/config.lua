local M = {}

local function get_env_bool(key, default)
  local value = vim.fn.getenv(key)
  if value == vim.NIL or value == "" then
    return default
  end
  return value:lower() == "true" or value == "1"
end

local function get_config()
  return {
    debug = get_env_bool("SYSINIT_DEBUG", false),
  }
end

local _config = nil

function M.get()
  if not _config then
    _config = get_config()
  end
  return _config
end

return M
