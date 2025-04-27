-- core/module_loader.lua
local M = {}

function M.get_plugin_specs(module_system)
    local specs = {}
    for category, modules in pairs(module_system) do
        for _, module_name in ipairs(modules) do
            local ok, spec = pcall(require, string.format("lua/%s/%s", category, module_name))
            if ok then
                table.insert(specs, spec)
            else
                vim.notify(string.format("Failed to load plugin spec for lua/%s/%s: %s", category, module_name, spec),
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
                local module_path = string.format("lua/%s/%s", category, module_name)
                local module = require(module_path)
                if type(module.setup) == "function" then
                    module.setup()
                else
                    vim.notify(string.format("Module %s has no setup function", module_path), vim.log.levels.WARN)
                end
            end)
            if not ok then
                vim.notify(string.format("Failed to setup lua/%s/%s: %s", category, module_name, err),
                    vim.log.levels.ERROR)
            end
        end
    end
end

return M
