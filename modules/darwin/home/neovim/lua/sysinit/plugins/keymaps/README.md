# Neovim Keymapping System

This is a modular keymapping system for Neovim that provides consistent keybindings across both Neovim and VSCode-Neovim.

## Overview

The keymapping system is organized into logical groups, each responsible for a specific type of functionality (buffers, code, git, etc.). This makes it easier to:

1. Maintain and organize keybindings
2. Add new keybindings to specific categories
3. Share keybindings between Neovim and VSCode
4. Provide a consistent key interface regardless of environment

## Directory Structure

```
keymaps/
├── README.md
├── init.lua           # Core keymapping loader
├── pallete.lua        # Legacy wrapper for compatibility
└── groups/            # Group modules directory
    ├── buffer.lua     # Buffer-related keybindings
    ├── code.lua       # Code-related keybindings
    ├── debug.lua      # Debugging keybindings
    ├── explorer.lua   # File explorer keybindings
    ├── fold.lua       # Code folding keybindings
    ├── git.lua        # Git-related keybindings
    ├── llm.lua        # LLM-related keybindings
    ├── lsp.lua        # LSP-related keybindings
    ├── notifications.lua # Notification keybindings
    ├── problems.lua   # Problems/diagnostics keybindings
    ├── search.lua     # Search-related keybindings
    ├── split.lua      # Window split keybindings
    ├── terminal.lua   # Terminal keybindings
    ├── view.lua       # View-related keybindings
    └── window.lua     # Window operation keybindings
```

## How It Works

1. The main `init.lua` file loads all group modules
2. Each group module registers its keybindings with the main module
3. The system automatically configures the appropriate implementation (Neovim or VSCode)

## Adding New Keybindings

To add a new keybinding to an existing group:

1. Locate the appropriate group module in the `groups/` directory
2. Add a new entry to the `bindings` table in the `setup()` function
3. Specify both Neovim command and VSCode command for cross-environment compatibility

Example:

```lua
-- In groups/git.lua
keymaps.register_group("g", keymaps.group_icons.git .. " Git", {
    -- Existing bindings...
    {
        key = "s",
        desc = "Git Status",
        neovim_cmd = "<cmd>Git<CR>",
        vscode_cmd = "git.status"
    }
    -- More bindings...
})
```

## Creating a New Group

To create a completely new group of keybindings:

1. Create a new file in the `groups/` directory (e.g., `mynewgroup.lua`)
2. Define a module with a `setup()` function that registers the group
3. Add the new group to the list in `init.lua`

Example:

```lua
-- mynewgroup.lua
local M = {}
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    keymaps.register_group("x", "My New Group", {
        {
            key = "a",
            desc = "My Action",
            neovim_cmd = "<cmd>MyCommand<CR>",
            vscode_cmd = "extension.myCommand"
        }
    })
end

M.plugins = {}
return M
```

Then add "mynewgroup" to the list of groups in `init.lua`.

## Icons

Icons for groups are defined in the `group_icons` table in `init.lua`. These provide visual indicators in the which-key menu.
