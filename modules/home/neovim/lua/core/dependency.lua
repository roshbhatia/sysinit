local M = {}

-- Dependency graph representation
M.graph = {}
M.loaded = {}

function M.add_dependency(module, depends_on)
    if not M.graph[module] then
        M.graph[module] = {}
    end
    table.insert(M.graph[module], depends_on)
end

function M.sort_dependencies()
    local sorted = {}
    local visited = {}
    
    local function visit(module)
        if visited[module] then return end
        visited[module] = true
        
        for _, dep in ipairs(M.graph[module] or {}) do
            visit(dep)
        end
        table.insert(sorted, module)
    end
    
    for module, _ in pairs(M.graph) do
        visit(module)
    end
    
    return sorted
end

return M
