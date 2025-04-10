-- Bootstrap file for sysinit.nvim
-- This file initializes the core system and handles plugin management

local M = {}

-- Initialize the core system and get plugin specs
function M.init()
  -- First require core
  local ok, core = pcall(require, "core")
  if not ok then
    vim.notify("Failed to load core module: " .. tostring(core), vim.log.levels.ERROR)
    vim.notify("Lua package path: " .. package.path, vim.log.levels.INFO)
    vim.notify("Lua cpath: " .. package.cpath, vim.log.levels.INFO)
    return {}
  end
  
  -- Check core module type
  vim.notify("Core module type: " .. type(core), vim.log.levels.INFO)
  vim.notify("Core module keys: " .. table.concat(vim.tbl_keys(core), ", "), vim.log.levels.INFO)
  
  -- Initialize if available
  if core and type(core.init) == "function" then
    local init_ok, init_result = pcall(core.init)
    if not init_ok then
      vim.notify("Error calling core.init(): " .. tostring(init_result), vim.log.levels.ERROR)
      return {}
    end
    return init_result or core.get_plugin_specs()
  else
    vim.notify("Core module does not have init function", vim.log.levels.ERROR)
    vim.notify("Core module init type: " .. type(core.init), vim.log.levels.INFO)
    return {}
  end
end

-- Ensure bootstrap function returns the full module
function M.bootstrap()
  print("Bootstrap function called")
  return M  -- Return the full module, not just a boolean
end

-- Maintain all previous functions
function M.get_plugin_specs()
  return M.init()
end

function M.setup_lazy()
  -- Existing setup_lazy implementation
end

function M.setup_options()
  -- Existing setup_options implementation
end

return M  -- Explicitly return the module
