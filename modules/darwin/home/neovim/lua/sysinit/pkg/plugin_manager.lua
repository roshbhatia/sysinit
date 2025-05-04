local plugin_manager = {}

function plugin_manager.setup_package_manager(specs)
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git",
                       "--branch=stable", lazypath})
    end
    vim.opt.rtp:prepend(lazypath)

    local core_specs = {{
        "vhyrro/luarocks.nvim",
        priority = 1000,
        dependencies = {"nvim-lua/plenary.nvim"},
        opts = {
            rocks = {},
            rocks_path = vim.fn.stdpath("data") .. "/luarocks",
            lua_path = vim.fn.stdpath("data") .. "/luarocks/share/lua/5.1/?.lua;" .. vim.fn.stdpath("data") ..
                "/luarocks/share/lua/5.1/?/init.lua",
            lua_cpath = vim.fn.stdpath("data") .. "/luarocks/lib/lua/5.1/?.so",
            create_dirs = true,
            install = {
                only_deps = false,
                flags = {"--local", "--force-config"}
            },
            show_progress = true
        }
    }}

    for _, spec in ipairs(specs) do
        table.insert(core_specs, spec)
    end

    for _, spec in ipairs(specs) do
        table.insert(core_specs, spec)
    end

    require("lazy").setup({
        root = vim.fn.stdpath("data") .. "/lazy",
        lockfile = vim.fn.stdpath("data") .. "/lazy/lazy-lock.json",

        rocks = {
            enabled = true,
            root = vim.fn.stdpath("data") .. "/lazy-rocks"
        },

        spec = core_specs,

        performance = {
            rtp = {
                disabled_plugins = {"gzip", "matchit", "matchparen", "netrwPlugin", "tarPlugin", "tohtml", "tutor",
                                    "zipPlugin"}
            }
        },
        change_detection = {
            notify = false
        }
    })
end

function plugin_manager.collect_plugin_specs(modules)
    local specs = {}

    for _, M in ipairs(modules) do
        if plugin_manager.plugins then
            for _, plugin in ipairs(plugin_manager.plugins) do
                table.insert(specs, plugin)
            end
        end
    end

    return specs
end

function plugin_manager.run_plugin_post_setup(modules)
    for _, M in ipairs(modules) do
        if plugin_manager.setup then
            plugin_manager.setup()
        end
    end
end

return plugin_manager

