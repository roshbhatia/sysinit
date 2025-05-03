local M = {}

M.plugins = {{
    {plugin_name}, -- Required: Name of the plugin in string format (e.g. 'nvim-treesitter/nvim-treesitter')

    -- Optional fields with defaults
    lazy = true, -- Recommended: Enable lazy loading
    event = 'VeryLazy', -- Recommended: Load on VeryLazy event

    -- Advanced configuration (uncomment and modify as needed)
    -- priority = 1000,        -- Set if plugin needs to load early
    -- branch = "main",        -- Specify a git branch
    -- version = "*",          -- Specify version constraints

    -- Dependencies configuration
    -- dependencies = {
    --     -- Example: {'dependency/name', branch = 'main', opts = {}}
    -- },

    -- Plugin configuration
    opts = {
        -- Configuration passed directly to plugin's setup()
        -- Example: theme = "dark", indent = 2
    }

    -- Manual configuration (use only if opts is insufficient)
    -- config = function()
    --     require({plugin_name}).setup({
    --         -- your configuration here
    --     })
    -- end
}}

-- You can add more plugins to this table
-- M.plugins[2] = { ... }

return M
