local M = {}

M.modules = {}
M.plugin_specs = {}
M._initialized = false

function M.register(name, module)
    if not module then return M end
    M.modules[name] = module
    
    -- Register module dependencies
    if module.depends_on then
        local dep = require("core.dependency")
        for _, dependency in ipairs(module.depends_on) do
            dep.add_dependency(name, dependency)
        end
    end
    
    -- Add plugins to specs if they exist
    if module.plugins then
        for _, plugin in ipairs(module.plugins) do
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
    
    -- Initialize state management
    require("core.state")
    
    -- Load modules in dependency order
    require("modules")
    local dep = require("core.dependency")
    local load_order = dep.sort_dependencies()
    
    -- Load modules in correct order
    for _, module_name in ipairs(load_order) do
        local module = M.modules[module_name]
        if module and type(module.setup) == "function" then
            vim.notify("Loading module: " .. module_name, vim.log.levels.INFO)
            module.setup()
        end
    end
    
    M._initialized = true
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

-- Add test runner command
vim.api.nvim_create_user_command("TestModule", function(opts)
    require("core.test").run_interactive_test(opts.args)
end, {
    nargs = 1,
    complete = function()
        return vim.tbl_keys(require("core.test").tests)
    end,
})

-- Add validation command
vim.api.nvim_create_user_command("ValidateCore", function()
    local validate = require("core.validate")
    local results = {
        dependencies = validate.validate_dependency_graph(),
        state = validate.validate_state_management(),
        modules = validate.validate_module_loading()
    }
    
    -- Create results buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    
    local lines = {"Core System Validation Results", "==========================", ""}
    
    for component, result in pairs(results) do
        table.insert(lines, string.format("%s: %s", component, result.status))
        for _, msg in ipairs(result.messages) do
            table.insert(lines, "  - " .. msg)
        end
        table.insert(lines, "")
    end
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Show in split
    vim.cmd("vsplit")
    vim.api.nvim_win_set_buf(0, buf)
end, {})

return M
