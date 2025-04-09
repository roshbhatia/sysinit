# Neovim Configuration Design Document

## Overview

This document outlines the architecture and design decisions for the Neovim configuration. The goal is to create a VSCode-like experience while leveraging Neovim's speed and extensibility.

## Core Principles

1. **VSCode Familiarity**: The configuration should feel familiar to VSCode users
2. **Performance**: Prioritize speed and responsiveness
3. **Stability**: Avoid errors that require Neovim restarts
4. **Modularity**: Well-organized code with clear separation of concerns
5. **Discoverability**: Features should be easy to find and use

## Directory Structure

```
modules/home/neovim/
├── init.lua                  # Main configuration entry point
├── lua/
│   ├── core/                 # Core functionality
│   │   ├── keymaps.lua       # Key mappings
│   │   ├── options.lua       # Vim options
│   │   ├── autocmds.lua      # Autocommands
│   │   └── utils.lua         # Utility functions
│   ├── plugins/              # Plugin configurations
│   │   ├── init.lua          # Plugin setup with lazy.nvim
│   │   ├── lsp/              # LSP configurations
│   │   │   ├── init.lua      # LSP setup
│   │   │   ├── mason.lua     # Mason configuration
│   │   │   └── servers/      # Individual server configs
│   │   ├── editor/           # Editor enhancement plugins
│   │   ├── ui/               # UI plugins
│   │   ├── tools/            # Development tools
│   │   └── coding/           # Code-specific plugins
│   └── config/               # Plugin-specific configurations
│       ├── chadtree.lua      # CHADTree configuration
│       ├── startify.lua      # Startify configuration
│       └── whichkey.lua      # Which-key configuration
├── snippets/                 # Custom snippets
├── ftplugin/                 # Filetype-specific settings
└── plugin/                   # Global plugin settings
```

## Plugin Architecture

We'll use Lazy.nvim for plugin management with a modular approach:

```lua
-- plugins/init.lua
return {
  -- Core plugins
  require("plugins.editor"),
  require("plugins.ui"),
  require("plugins.lsp"),
  require("plugins.tools"),
  require("plugins.coding"),
}
```

Each module will return a table of plugin specifications:

```lua
-- plugins/editor.lua
return {
  -- File explorer
  {
    "ms-jpq/chadtree",
    branch = "chad",
    build = "python3 -m chadtree deps",
    config = function() require("config.chadtree") end,
  },
  -- Other editor plugins...
}
```

## Key Features Implementation

### VSCode-Like File Explorer (CHADTree)

CHADTree will be configured to mimic VSCode's explorer with:
- File icons
- Git status indicators
- Intuitive keybindings
- Drag-and-drop functionality

```lua
-- config/chadtree.lua
vim.g.chadtree_settings = {
  view = {
    width = 30,
    open_direction = "left",
  },
  theme = {
    icon_colour_set = "vscode",
    text_colour_set = "env",
  },
  keymap = {
    -- VSCode-like keymappings
  },
}
```

### Fast Completion with coq_nvim

coq_nvim will provide fast, non-blocking completion:

```lua
-- plugins/coding.lua
{
  "ms-jpq/coq_nvim",
  branch = "coq",
  dependencies = {
    { "ms-jpq/coq.artifacts", branch = "artifacts" },
    { "ms-jpq/coq.thirdparty", branch = "3p" },
  },
  config = function()
    vim.g.coq_settings = {
      auto_start = "shut-up",
      keymap = {
        recommended = true,
        jump_to_mark = "<C-Space>",
      },
      clients = {
        snippets = {
          enabled = true,
          warn = {},
        },
        tags = { enabled = true },
        lsp = { enabled = true },
      },
    }
  end,
}
```

### Mason for LSP Management

Mason will manage language servers, linters, and formatters:

```lua
-- plugins/lsp/mason.lua
{
  "williamboman/mason.nvim",
  config = function()
    require("mason").setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })
  end,
},
{
  "williamboman/mason-lspconfig.nvim",
  config = function()
    require("mason-lspconfig").setup({
      ensure_installed = {
        "pyright", "tsserver", "lua_ls", "gopls", "jsonls",
        "yamlls", "bashls", "clangd", "rust_analyzer"
      },
      automatic_installation = true,
    })
  end,
}
```

### Session Management

A combination of Startify and persistence.nvim for comprehensive session management:

```lua
-- config/startify.lua
-- Custom Startify configuration for session management
vim.g.startify_session_dir = vim.fn.stdpath("data") .. "/sessions"
vim.g.startify_session_autoload = 1
vim.g.startify_session_persistence = 1
vim.g.startify_custom_header = { ... } -- Custom header

-- plugins/editor.lua
{
  "folke/persistence.nvim",
  event = "BufReadPre",
  config = function()
    require("persistence").setup({
      dir = vim.fn.expand(vim.fn.stdpath("data") .. "/sessions/"),
      options = { "buffers", "curdir", "tabpages", "winsize" },
    })
  end,
}
```

### Theme Management with Themery

Themery for easy theme switching:

```lua
-- plugins/ui.lua
{
  "zaldih/themery.nvim",
  config = function()
    require("themery").setup({
      themes = {
        { name = "Tokyonight Storm", colorscheme = "tokyonight-storm" },
        { name = "Tokyonight Night", colorscheme = "tokyonight-night" },
        { name = "Catppuccin Mocha", colorscheme = "catppuccin-mocha" },
        { name = "Catppuccin Macchiato", colorscheme = "catppuccin-macchiato" },
        { name = "GitHub Dark", colorscheme = "github_dark" },
        { name = "GitHub Light", colorscheme = "github_light" },
        { name = "Dracula", colorscheme = "dracula" },
        { name = "Gruvbox", colorscheme = "gruvbox" },
      },
      themeConfigFile = vim.fn.stdpath("config") .. "/lua/core/theme.lua",
      livePreview = true,
    })
  end,
}
```

### Enhanced UI with noice.nvim and nvim-notify

Modern, VS Code-like UI components:

```lua
-- plugins/ui.lua
{
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  config = function()
    require("noice").setup({
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = false,
      },
    })
  end,
}
```

### Key Mapping Organization

The key mapping strategy will use Which-key to create VSCode-like commands:

```lua
-- config/whichkey.lua
local which_key = require("which-key")

which_key.setup({
  plugins = {
    marks = true,
    registers = true,
    spelling = { enabled = false },
    presets = { ... },
  },
  window = { border = "single", padding = { 2, 2, 2, 2 } },
  layout = { spacing = 6 },
})

-- Register main leader groups
which_key.register({
  f = { name = "󰈔 Find" },
  g = { name = " Git" },
  c = { name = "󰌵 Code" },
  d = { name = " Debug" },
  t = { name = "󰙅 Toggle" },
  b = { name = "󰓩 Buffer" },
  w = { name = "󰖮 Window" },
  h = { name = "⚓ Harpoon" },
  -- More categories...
}, { prefix = "<leader>" })
```

## Implementation Strategy

1. **Bootstrap Lazy.nvim**: Initialize plugin manager
2. **Core Settings**: Set up basic Vim options and key mappings
3. **Core Plugins**: Implement CHADTree, coq, and LSP support
4. **Enhanced Experience**: Add UI enhancements and specialized tools
5. **Testing**: Ensure the configuration works across different environments

## Performance Considerations

1. **Lazy Loading**: Load plugins only when needed
2. **Event-based loading**: Utilize events to defer plugin loading
3. **Conditional loading**: Skip plugins based on conditions
4. **Minimal default plugins**: Keep the default set small

```lua
-- Example of performance-focused plugin config
{
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope", -- Load only when command is used
  keys = { -- Load when these keys are pressed
    { "<leader>ff", desc = "Find Files" },
    { "<leader>fg", desc = "Live Grep" },
  },
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function() ... end,
}
```

## Error Handling and Stability

1. **pcall for risky operations**: Wrap potentially failing code
2. **Fallback mechanisms**: Provide alternatives when preferred options fail
3. **Health checks**: Add custom healthchecks for diagnostics
4. **Conditional plugin loading**: Skip plugins that might cause issues in certain environments

```lua
-- Example stability pattern
local status_ok, plugin = pcall(require, "plugin_name")
if not status_ok then
  vim.notify("Plugin failed to load: plugin_name", vim.log.levels.WARN)
  return
end

plugin.setup({...})
```

## Extension Points

1. **Local configuration**: Support for machine-specific settings
2. **Project-specific settings**: Override configs based on project
3. **Language-specific settings**: Configure per language

## Testing Approach

1. **make test-neovim**: Command to test in isolation
2. **Headless testing**: For automated tests
3. **Checkpoint testing**: Test configs at key implementation stages

## Success Metrics

1. **Startup time < 100ms**: Measure with --startuptime
2. **No errors on startup**: Clean :checkhealth output
3. **Feature parity**: Match all critical VSCode features
4. **User experience**: Similar workflow to VSCode