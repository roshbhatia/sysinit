local M = {}

function M.validate_dependency_graph()
    local dep = require("core.dependency")
    local results = {status = "OK", messages = {}}
    
    -- Check for circular dependencies
    local function has_cycle(graph)
        local visited = {}
        local path = {}
        
        local function visit(node)
            if path[node] then
                return true, node
            end
            if visited[node] then return false end
            
            visited[node] = true
            path[node] = true
            
            for _, dep in ipairs(graph[node] or {}) do
                local has_cycle, cycle_start = visit(dep)
                if has_cycle then return true, cycle_start end
            end
            
            path[node] = nil
            return false
        end
        
        for node in pairs(graph) do
            local has_cycle, cycle_start = visit(node)
            if has_cycle then
                return true, cycle_start
            end
        end
        return false
    end
    
    local cycle_exists, cycle_start = has_cycle(dep.graph)
    if cycle_exists then
        results.status = "ERROR"
        table.insert(results.messages, "Circular dependency detected starting at: " .. cycle_start)
    end
    
    return results
end

function M.validate_state_management()
    local state = require("core.state")
    local results = {status = "OK", messages = {}}
    
    -- Test state operations
    local test_module = "test_module"
    local test_key = "test_key"
    local test_value = "test_value"
    
    state.set(test_module, test_key, test_value)
    local retrieved = state.get(test_module, test_key)
    
    if retrieved ~= test_value then
        results.status = "ERROR"
        table.insert(results.messages, "State value mismatch")
    end
    
    return results
end

function M.validate_module_loading()
    local core = require("core")
    local results = {status = "OK", messages = {}}
    
    for name, module in pairs(core.modules) do
        if not module.setup then
            table.insert(results.messages, string.format("Module %s missing setup function", name))
        end
    end
    
    if #results.messages > 0 then
        results.status = "ERROR"
    end
    
    return results
end

return M
