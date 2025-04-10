local M = {}

-- Dependency graph representation
M.graph = {}
M.plugin_deps = {}
M.loaded = {}

-- Add a module dependency
function M.add_dependency(module, depends_on)
    if not M.graph[module] then
        M.graph[module] = {}
    end
    -- Check for circular dependencies
    if M._is_circular(depends_on, module) then
        vim.notify(
            string.format("Circular dependency detected: %s and %s depend on each other", module, depends_on),
            vim.log.levels.ERROR
        )
        return false
    end
    
    table.insert(M.graph[module], depends_on)
    return true
end

-- Add a plugin dependency
function M.add_plugin_dependency(plugin, depends_on)
    if not M.plugin_deps[plugin] then
        M.plugin_deps[plugin] = {}
    end
    table.insert(M.plugin_deps[plugin], depends_on)
end

-- Detects circular dependencies
function M._is_circular(start_module, target_module, visited)
    visited = visited or {}
    if start_module == target_module then return true end
    if visited[start_module] then return false end
    
    visited[start_module] = true
    for _, dep in ipairs(M.graph[start_module] or {}) do
        if M._is_circular(dep, target_module, visited) then
            return true
        end
    end
    
    return false
end

-- Topological sort for dependency resolution
function M.sort_dependencies()
    local sorted = {}
    local visited = {}
    local temp_marks = {}  -- For detecting cycles
    
    -- Visit function for DFS
    local function visit(module)
        if temp_marks[module] then
            vim.notify("Cycle detected in module dependencies", vim.log.levels.ERROR)
            return false
        end
        
        if visited[module] then return true end
        
        temp_marks[module] = true
        
        for _, dep in ipairs(M.graph[module] or {}) do
            local success = visit(dep)
            if not success then
                return false
            end
        end
        
        temp_marks[module] = nil
        visited[module] = true
        table.insert(sorted, module)
        return true
    end
    
    -- Process all modules
    local all_modules = {}
    for module, _ in pairs(M.graph) do
        all_modules[module] = true
    end
    
    -- Add dependent modules that might not have their own dependencies
    for _, deps in pairs(M.graph) do
        for _, dep in ipairs(deps) do
            all_modules[dep] = true
        end
    end
    
    -- Visit all nodes
    for module, _ in pairs(all_modules) do
        if not visited[module] then
            local success = visit(module)
            if not success then
                return {}  -- Return empty list on failure
            end
        end
    end
    
    -- Reverse the result to get correct topological order
    local result = {}
    for i = #sorted, 1, -1 do
        table.insert(result, sorted[i])
    end
    
    return result
end

-- Check for conflicts between plugins
function M.detect_conflicts()
    local conflicts = {}
    
    -- Simple conflict detection based on known incompatibilities
    local known_conflicts = {
        -- Add known conflicting plugins here
        ["oil.nvim"] = {"mini.files"},
        ["themery.nvim"] = {"appearances.nvim"},
    }
    
    for plugin, conflicting in pairs(known_conflicts) do
        for _, conflict in ipairs(conflicting) do
            if M.plugin_deps[plugin] and M.plugin_deps[conflict] then
                table.insert(conflicts, {plugin1 = plugin, plugin2 = conflict})
            end
        end
    end
    
    return conflicts
end

-- Get a visualization of the dependency graph (for debugging)
function M.visualize_graph()
    local lines = {"Module Dependency Graph:"}
    
    for module, deps in pairs(M.graph) do
        table.insert(lines, module .. " depends on:")
        for _, dep in ipairs(deps) do
            table.insert(lines, "  - " .. dep)
        end
    end
    
    return lines
end

return M