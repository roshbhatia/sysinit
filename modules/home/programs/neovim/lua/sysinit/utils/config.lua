local M = {}

local default_config = {
  debug = false,
}

function M.get()
  return default_config
end

return M
