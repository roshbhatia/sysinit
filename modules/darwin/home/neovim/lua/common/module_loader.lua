local M = {}

function M.get_plugin_specs(modules)
    local specs = {}

    for _, module in ipairs(modules) do
        if module.plugins then
            for _, plugin in ipairs(module.plugins) do
                table.insert(specs, plugin)
            end
        end
    end

    return specs
end

function M.setup_modules(modules)
    for _, module in ipairs(modules) do
        if module.setup then
            module.setup()
        end
    end
end

return M
