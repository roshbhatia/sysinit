-- This plugin file contains fixes that need to run early during Neovim initialization

-- Update the Lua package path to include our local config directories
local function update_package_path()
  local config_path = vim.fn.stdpath('config')
  
  -- Add our lua directories to the package.path
  package.path = string.format(
    "%s;%s/lua/?.lua;%s/lua/?/init.lua",
    package.path,
    config_path,
    config_path
  )
  
  -- Add any C modules to the package.cpath
  package.cpath = string.format(
    "%s;%s/lua/?.so",
    package.cpath,
    config_path
  )
end

-- Call the function to update package path
update_package_path()

-- Create failsafe require function
_G.safe_require = function(module)
  local status, result = pcall(require, module)
  if not status then
    vim.notify("Failed to load module: " .. module, vim.log.levels.WARN)
    return nil
  end
  return result
end