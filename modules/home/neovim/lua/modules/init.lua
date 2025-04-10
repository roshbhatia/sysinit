-- Module registration
-- This file loads all modules in the correct order

-- Core modules (these are initialized first by the system)
require("modules.keybindings")
require("modules.layout")
require("modules.themes")

-- Feature modules
require("modules.lsp")
require("modules.editor")

-- Register a health check command
vim.api.nvim_create_user_command("SysinitHealth", function()
  local health = require("health")
  local core = require("core")
  local state = require("core.state")
  
  local function check_module(name)
    local module = core.get_module(name)
    if not module then
      health.report_error(string.format("Module %s is not registered", name))
      return false
    end
    
    -- Check if module has required fields
    if not module.setup then
      health.report_warn(string.format("Module %s does not have a setup function", name))
    end
    
    if not module.plugins or #module.plugins == 0 then
      health.report_info(string.format("Module %s does not define any plugins", name))
    end
    
    return true
  end
  
  -- Header
  health.report_start("Sysinit Configuration Health Check")
  health.report_info("Version: 1.0.0")
  
  -- Check core system
  health.report_start("Core System")
  local validate = require("core.validate")
  local results = validate.validate_all()
  
  for component, result in pairs(results) do
    if result.status == "OK" then
      health.report_ok(string.format("%s: %s", component, table.concat(result.messages, ", ")))
    elseif result.status == "WARNING" then
      health.report_warn(string.format("%s: %s", component, table.concat(result.messages, ", ")))
    else
      health.report_error(string.format("%s: %s", component, table.concat(result.messages, ", ")))
    end
  end
  
  -- Check all modules
  local required_modules = {
    "keybindings",
    "layout",
    "themes",
    "lsp",
    "editor",
  }
  
  health.report_start("Modules")
  for _, name in ipairs(required_modules) do
    if check_module(name) then
      health.report_ok(string.format("Module %s is loaded", name))
    end
  end
  
  -- Check state
  health.report_start("State Management")
  local state_count = 0
  for module_name, values in pairs(state.store) do
    local count = 0
    for k, _ in pairs(values) do
      if k ~= "_persistent" then
        count = count + 1
      end
    end
    state_count = state_count + count
    health.report_info(string.format("Module %s has %d state values", module_name, count))
  end
  
  if state_count == 0 then
    health.report_warn("No module state values found")
  else
    health.report_ok(string.format("Found %d state values across all modules", state_count))
  end
  
  -- Check plugins managed by lazy.nvim
  health.report_start("Plugins")
  local ok, lazy_stats = pcall(require, "lazy.stats")
  if ok then
    local stats = lazy_stats.stats()
    health.report_info(string.format("Total plugins: %d", stats.count))
    health.report_info(string.format("Loaded plugins: %d", stats.loaded))
    health.report_info(string.format("Startup time: %.2fms", stats.startuptime))
  else
    health.report_warn("lazy.nvim stats not available")
  end
  
  -- Module loading order
  health.report_start("Module Loading Order")
  local loading_info = core.get_loading_info()
  for i, info in ipairs(loading_info) do
    local deps = info.dependencies and table.concat(info.dependencies, ", ") or "none"
    health.report_info(string.format("%d. %s (deps: %s)", i, info.name, deps))
  end
  
  -- Final recommendation
  health.report_start("Recommendations")
  if state_count < 5 then
    health.report_warn("Consider using state management for better module communication")
  end
  
  local test = require("core.test")
  local test_count = 0
  for _ in pairs(test.tests) do
    test_count = test_count + 1
  end
  
  if test_count < #required_modules then
    health.report_warn(string.format("Only %d test cases defined. Consider adding more tests.", test_count))
  else
    health.report_ok(string.format("Found %d test cases", test_count))
  end
end, {})

-- This module doesn't need to return anything
return {}
