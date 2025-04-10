local M = {}

-- Validate the dependency graph
function M.validate_dependency_graph()
    local dep = require("core.dependency")
    local core = require("core")
    
    local result = {
        status = "OK",
        messages = {}
    }
    
    -- Check for circular dependencies
    local function check_circular_dependencies()
        local modules = vim.tbl_keys(core.modules)
        
        for _, module in ipairs(modules) do
            for _, dep_module in ipairs(modules) do
                if module ~= dep_module then
                    if dep._is_circular(module, dep_module) and dep._is_circular(dep_module, module) then
                        table.insert(result.messages, string.format(
                            "Circular dependency detected: %s <-> %s",
                            module, dep_module
                        ))
                        result.status = "ERROR"
                    end
                end
            end
        end
    end
    
    -- Check for missing dependencies
    local function check_missing_dependencies()
        local all_modules = vim.tbl_keys(core.modules)
        
        for module, deps in pairs(dep.graph) do
            for _, dependency in ipairs(deps) do
                if not vim.tbl_contains(all_modules, dependency) then
                    table.insert(result.messages, string.format(
                        "Module %s depends on %s, but it does not exist",
                        module, dependency
                    ))
                    result.status = "ERROR"
                end
            end
        end
    end
    
    -- Validate topological sort
    local function validate_topological_sort()
        local order = dep.sort_dependencies()
        if vim.tbl_isempty(order) then
            table.insert(result.messages, "Dependency resolution failed to produce a loading order")
            result.status = "ERROR"
            return
        end
        
        -- Check if order respects dependencies
        local loaded = {}
        for _, module in ipairs(order) do
            loaded[module] = true
            
            -- Check if all dependencies are loaded before this module
            local deps = dep.graph[module] or {}
            for _, dependency in ipairs(deps) do
                if not loaded[dependency] then
                    table.insert(result.messages, string.format(
                        "Invalid loading order: %s should load after %s",
                        module, dependency
                    ))
                    result.status = "ERROR"
                end
            end
        end
    end
    
    -- Run validations
    check_circular_dependencies()
    check_missing_dependencies()
    validate_topological_sort()
    
    -- If no errors, add success message
    if result.status == "OK" then
        table.insert(result.messages, "Dependency graph is valid")
    end
    
    return result
end

-- Validate state management
function M.validate_state_management()
    local state = require("core.state")
    
    local result = {
        status = "OK",
        messages = {}
    }
    
    -- Check if state store is properly initialized
    if not state.store then
        table.insert(result.messages, "State store is not initialized")
        result.status = "ERROR"
    end
    
    -- Check if event system is working
    local event_test_passed = false
    local unsub = state.on("validate.test", function()
        event_test_passed = true
    end)
    
    state.emit("validate.test")
    unsub() -- Clean up listener
    
    if not event_test_passed then
        table.insert(result.messages, "Event system is not working properly")
        result.status = "ERROR"
    end
    
    -- Check state persistence
    if state.storage_path then
        local persistence_enabled = true
        table.insert(result.messages, "State persistence is enabled at: " .. state.storage_path)
        
        -- Check if we can write to the directory
        local dir = vim.fn.fnamemodify(state.storage_path, ":h")
        if vim.fn.isdirectory(dir) ~= 1 then
            table.insert(result.messages, "Warning: Persistence directory does not exist")
            persistence_enabled = false
        end
        
        if not persistence_enabled then
            table.insert(result.messages, "State persistence is configured but may not work")
            result.status = "WARNING"
        end
    else
        table.insert(result.messages, "State persistence is disabled")
    end
    
    -- If no errors, add success message
    if result.status == "OK" then
        table.insert(result.messages, "State management system is valid")
    end
    
    return result
end

-- Validate module loading
function M.validate_module_loading()
    local core = require("core")
    
    local result = {
        status = "OK",
        messages = {}
    }
    
    -- Check if modules are loaded
    if vim.tbl_isempty(core.modules) then
        table.insert(result.messages, "No modules are registered")
        result.status = "ERROR"
        return result
    end
    
    -- Check each module has required fields
    local module_count = 0
    local modules_with_setup = 0
    local modules_with_plugins = 0
    
    for name, module in pairs(core.modules) do
        module_count = module_count + 1
        
        if type(module.setup) == "function" then
            modules_with_setup = modules_with_setup + 1
        else
            table.insert(result.messages, string.format(
                "Module %s does not have a setup function",
                name
            ))
        end
        
        if module.plugins and #module.plugins > 0 then
            modules_with_plugins = modules_with_plugins + 1
        end
    end
    
    -- Add statistics
    table.insert(result.messages, string.format(
        "Total modules: %d (%d with setup, %d with plugins)",
        module_count, modules_with_setup, modules_with_plugins
    ))
    
    -- Check if core was initialized
    if not core._initialized then
        table.insert(result.messages, "Core system is not initialized")
        result.status = "WARNING"
    end
    
    -- Add info about loading order
    if core._loading_order then
        table.insert(result.messages, "Module loading order is established")
    else
        table.insert(result.messages, "Module loading order is not established")
        result.status = "WARNING"
    end
    
    return result
end

-- Run all validations
function M.validate_all()
    return {
        dependencies = M.validate_dependency_graph(),
        state = M.validate_state_management(),
        modules = M.validate_module_loading()
    }
end

return M