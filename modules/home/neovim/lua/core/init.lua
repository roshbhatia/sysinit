local M = {}

M.modules = {}
M.plugin_specs = {}
M._initialized = false
M._loading_order = nil

-- Register a module with the core system
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
    
    -- Notify state management system about new module
    local state = require("core.state")
    state.emit("core.module_registered", { name = name, module = module })
    
    return M
end

-- Initialize the core system and all modules
function M.init()
    if M._initialized then return end
    
    -- Initialize state management
    local state = require("core.state")
    state.enable_persistence()  -- Enable state persistence
    
    -- Load modules in dependency order
    require("modules")
    local dep = require("core.dependency")
    local load_order = dep.sort_dependencies()
    M._loading_order = load_order
    
    -- Check for plugin conflicts
    local conflicts = dep.detect_conflicts()
    if #conflicts > 0 then
        for _, conflict in ipairs(conflicts) do
            vim.notify(string.format(
                "Plugin conflict detected: %s and %s",
                conflict.plugin1, conflict.plugin2
            ), vim.log.levels.WARN)
        end
    end
    
    -- Load modules in correct order
    for _, module_name in ipairs(load_order) do
        local module = M.modules[module_name]
        if module and type(module.setup) == "function" then
            vim.notify("Loading module: " .. module_name, vim.log.levels.INFO)
            local ok, err = pcall(module.setup)
            if not ok then
                vim.notify("Error loading module " .. module_name .. ": " .. err, vim.log.levels.ERROR)
            end
        end
    end
    
    -- Emit initialization completed event
    state.emit("core.initialized", { modules = M.modules, load_order = load_order })
    
    M._initialized = true
    return M
end

-- Get all plugin specs for the lazy.nvim plugin manager
function M.get_plugin_specs()
    if not M._initialized then
        M.init()
    end
    return M.plugin_specs
end

-- Get information about module loading order
function M.get_loading_info()
    if not M._loading_order then
        local dep = require("core.dependency")
        M._loading_order = dep.sort_dependencies()
    end
    
    local info = {}
    for i, name in ipairs(M._loading_order) do
        local module = M.modules[name]
        table.insert(info, {
            name = name,
            order = i,
            dependencies = module.depends_on or {},
            has_setup = type(module.setup) == "function",
        })
    end
    
    return info
end

-- Force load all modules (skipping dependency order)
function M.load_all()
  for name, module in pairs(M.modules) do
    if type(module.setup) == "function" then
      vim.notify("Loading module: " .. name, vim.log.levels.INFO)
      local ok, err = pcall(module.setup)
      if not ok then
        vim.notify("Error loading module " .. name .. ": " .. err, vim.log.levels.ERROR)
      end
    end
  end
end

-- Get a module by name
function M.get_module(name)
    return M.modules[name]
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

-- Add system status command
vim.api.nvim_create_user_command("CoreStatus", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    
    -- Gather system info
    local lines = {"# System Status", ""}
    
    -- Module loading order
    table.insert(lines, "## Module Loading Order")
    for i, name in ipairs(M._loading_order or {}) do
        local module = M.modules[name]
        local deps = module.depends_on and table.concat(module.depends_on, ", ") or "none"
        table.insert(lines, string.format("%d. %s (deps: %s)", i, name, deps))
    end
    table.insert(lines, "")
    
    -- Plugin stats
    table.insert(lines, "## Plugin Statistics")
    table.insert(lines, string.format("Total plugins: %d", #M.plugin_specs))
    
    -- State info
    table.insert(lines, "")
    table.insert(lines, "## State Management")
    local state = require("core.state")
    for module_name, values in pairs(state.store) do
        table.insert(lines, string.format("### %s", module_name))
        for key, _ in pairs(values) do
            if key ~= "_persistent" then
                table.insert(lines, string.format("- %s", key))
            end
        end
    end
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Show in split
    vim.cmd("botright split")
    vim.api.nvim_win_set_buf(0, buf)
    
    -- Set as markdown
    vim.cmd("setlocal filetype=markdown")
    
    -- Close with q
    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
end, {})

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

-- Register core system tests
local test = require("core.test")
test.register_test("core_system", function()
    local tests = {
        function()
            print("Testing module registration...")
            local test_module = {
                setup = function() end
            }
            M.register("test_module", test_module)
            assert(M.modules.test_module, "Module should be registered")
            return true, "Module registration works"
        end,
        
        function()
            print("Testing dependency resolution...")
            local dep = require("core.dependency")
            local order = dep.sort_dependencies()
            assert(#order > 0, "Dependency order should not be empty")
            return true, "Dependency resolution works"
        end,
        
        function()
            print("Testing event bus...")
            local state = require("core.state")
            local event_received = false
            local unsub = state.on("test.event", function()
                event_received = true
            end)
            state.emit("test.event")
            assert(event_received, "Event should be received")
            unsub() -- Clean up
            return true, "Event bus works"
        end
    }
    
    for i, test_fn in ipairs(tests) do
        local success, msg = pcall(test_fn)
        if not success then
            return false, "Test " .. i .. " failed: " .. msg
        end
    end
    
    return true, "All core system tests passed"
end)

return M