# Copilot Instructions (RFC 2119)

# Common instructions

- NEVER add comments, unless directed to otherwise
- When refactoring, ALWAYS write the entire content to the file -- never write a partial amount and expect me to define things.
- When refactoring, ONLY use code I have previously defined OR documentation I explicitly provide, unless directed to otherwise.

## modules/darwin/home/neovim

This module is a neovim configuration built on lazy.nvim, adhering to the plugin spec format.

- We need to ensure that EVERY plugin definition adheres to the plugin spec format with some caveats.
- Plugin definitions MUST adhere to the plugin spec format provided.
- Plugin definitions MUST use `opts` for configuration whenever possible.
- Plugin definitions MUST NOT use `config` unless `opts` is insufficient.
- Plugin definitions MUST NOT define additional dependencies for installation. Dependencies SHOULD be noted but installed separately in a `plugins/shared` file.
- Plugin definitions MUST use lazy loading (`lazy = true`) and SHOULD load on the `VeryLazy` event unless otherwise specified.
- Plugin definitions MUST NOT include any additional functions unless a local function is required for setup.
- When refactoring, the entire content of the file MUST be rewritten, and only previously defined code or explicitly provided documentation MUST be used.
- Comments MUST NOT be added unless explicitly directed otherwise.
- Code changes MUST be as concise as possible, avoiding repetition of existing code.
-- There should NEVER be any additional functions, unless a local function is needed. The only things we should use to "setup" the plugins are either opts or the configure function params.

```lua
local M = {}

M.schema = {
    SpecSource = {
        plugin = "string?", -- Short plugin URL, expanded using config.git.url_format. Can also be a URL or directory.
        dir = "string?", -- Directory pointing to a local plugin.
        url = "string?", -- Custom git URL where the plugin is hosted.
        name = "string?", -- Custom name for the plugin directory and display name.
        dev = "boolean?" -- Use a local plugin directory if true.
    },
    SpecLoading = {
        dependencies = "LazySpec[]", -- List of plugin names or specs to load when the plugin loads.
        enabled = "boolean? or fun():boolean", -- Exclude plugin if false or function returns false.
        cond = "boolean? or fun(LazyPlugin):boolean", -- Similar to enabled but won't uninstall the plugin.
        priority = "number?" -- Priority for start plugins (lazy=false). Default is 50.
    },
    SpecSetup = {
        init = "fun(LazyPlugin)", -- Executed during startup for vim.g.* configuration.
        opts = "table or fun(LazyPlugin, opts:table)", -- Configuration table passed to Plugin.config().
        config = "fun(LazyPlugin, opts:table) or true", -- Executed when the plugin loads. Use opts when possible.
        main = "string?", -- Specify the main module for config() and opts().
        build = "fun(LazyPlugin) or string or false or list of build commands" -- Executed during install/update.
    },
    SpecLazyLoading = {
        lazy = "boolean?", -- Load plugin only when needed.
        event = "string? or string[] or fun(self:LazyPlugin, event:string[]):string[] or {event:string[]|string, pattern?:string[]|string}", -- Lazy-load on event.
        cmd = "string? or string[] or fun(self:LazyPlugin, cmd:string[]):string[]", -- Lazy-load on command.
        ft = "string? or string[] or fun(self:LazyPlugin, ft:string[]):string[]", -- Lazy-load on filetype.
        keys = "string? or string[] or LazyKeysSpec[] or fun(self:LazyPlugin, keys:string[]):(string | LazyKeysSpec)[]" -- Lazy-load on key mapping.
    },
    SpecVersioning = {
        branch = "string?", -- Repository branch.
        tag = "string?", -- Repository tag.
        commit = "string?", -- Repository commit.
        version = "string? or false", -- Version to use. Supports Semver ranges.
        pin = "boolean?", -- Exclude plugin from updates if true.
        submodules = "boolean?" -- Fetch git submodules if true. Defaults to true.
    },
    SpecAdvanced = {
        optional = "boolean?", -- Include only if specified elsewhere without optional.
        specs = "LazySpec", -- List of plugin specs defined in the plugin's scope.
        module = "false?", -- Prevent automatic loading of Lua module.
        import = "string?" -- Import the given spec module.
    }
}

return M
```

Plugin definitions SHOULD NOT define any more dependencies for install, just note that there is a dependency on something. If we need to install a dependency that's used by modules, we can create a `plugins/shared` file for that dependency itself.
