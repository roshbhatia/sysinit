local M = {}

function M.get_plugin_specs(module_system)
    local specs = {}
    for category, modules in pairs(module_system) do
        for _, module_name in ipairs(modules) do
            local ok, module = pcall(require, string.format("modules.%s.%s", category, module_name))
            if ok then
                if module.plugins and type(module.plugins) == "table" then
                    for _, plugin in ipairs(module.plugins) do
                        table.insert(specs, plugin)
                    end
                else
                    table.insert(specs, module)
                end
            else
                vim.notify(string.format("Failed to load plugin spec for %s.%s: %s", category, module_name, module),
                    vim.log.levels.ERROR)
            end
        end
    end
    return specs
end

function M.setup_modules(module_system)
    for category, modules in pairs(module_system) do
        for _, module_name in ipairs(modules) do
            local ok, err = pcall(function()
                local module_path = string.format("modules.%s.%s", category, module_name)
                local module = require(module_path)
                if type(module.setup) == "function" then
                    module.setup()
                end
            end)
            if not ok then
                vim.notify(string.format("Failed to setup module %s.%s: %s", category, module_name, err),
                    vim.log.levels.ERROR)
            end
        end
    end
end

return M
