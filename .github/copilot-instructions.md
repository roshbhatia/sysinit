# Common instructions

- NEVER add comments, unless directed to otherwise
- When refactoring, ALWAYS write the entire content to the file -- never write a partial amount and expect me to define things.
- When refactoring, ONLY use code I have previously defined OR documentation I explicitly provide, unless directed to otherwise.

## modules/darwin/home/neovim

This module is a neovim configuration built on lazy.nvim, adhering to the plugin spec format.

We need to ensure that EVERY plugin definition adheres to the plugin spec format with some caveats.

```lua
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
```

Plugin definitions SHOULD NOT define any more dependencies for install, just note that there is a dependency on something. If we need to install a dependency that's used by modules, we can create a `plugins/shared` file for that dependency itself.
