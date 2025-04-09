local M = {}

M.modules = {}
M.plugin_specs = {}
M._initialized = false

function M.register(name, module)
  if not module then return M end
  M.modules[name] = module
  
  -- Add plugins to specs if they exist
  if module.plugins then
    for _, plugin in ipairs(module.plugins) do
      -- Register panel plugins
      if plugin.panel then
        require("core.panel").register_panel_plugin(plugin.panel, plugin)
      end
      table.insert(M.plugin_specs, plugin)
    end
  end
  return M
end

function M.init()
  if M._initialized then return end
  M._initialized = true
  
  -- Load all module definitions first
  require("modules")
  return M
end

function M.get_plugin_specs()
  if not M._initialized then
    M.init()
  end
  return M.plugin_specs
end

function M.load_all()
  for name, module in pairs(M.modules) do
    if type(module.setup) == "function" then
      vim.notify("Loading module: " .. name, vim.log.levels.INFO)
      module.setup()
    end
  end
end

-- Add verify command
vim.api.nvim_create_user_command("VerifyModule", function(opts)
  require("core.verify").verify_module(opts.args)
end, {
  nargs = 1,
  complete = function()
    return vim.tbl_keys(require("core.verify").verifications)
  end,
})

return M
