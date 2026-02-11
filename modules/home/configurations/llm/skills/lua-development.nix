''
  ---
  name: lua-development
  description: Use when writing or modifying Lua code for Neovim plugins, WezTerm configuration, Hammerspoon automation, or Sketchybar widgets
  ---

  # Lua Development

  ## Overview

  Lua is used for Neovim plugin configuration, WezTerm terminal settings, Hammerspoon automation, and Sketchybar widgets. All Lua follows a consistent module pattern and is formatted with StyLua.

  ## Formatting

  - Tool: StyLua
  - Settings: `column_width=100`, `indent_width=2`, indent type `spaces`
  - Run: `task fmt:lua` (format) or `task fmt:lua:check` (verify)
  - Lint: `task fmt:lua:lint` (LSP diagnostics)
  - Full validation: `task fmt:lua:validate` (format + lint)

  ## Module Pattern

  All Lua modules use the `local M = {}` return pattern:

  ```lua
  local M = {}

  -- Module implementation here

  return M
  ```

  ## Neovim Plugin Pattern

  Neovim plugins are defined as lazy.nvim spec tables:

  ```lua
  local M = {}

  M.plugins = {
    {
      "plugin/name",
      opts = function()
        return {
          -- Configuration
        }
      end,
    }
  }

  return M
  ```

  ## Naming Conventions

  - Variables and functions: `snake_case`
  - Module names: `PascalCase`
  - Constants: `UPPER_SNAKE_CASE` (by convention, not enforced)

  ## Imports

  ```lua
  local module = require("path")
  -- or destructured:
  local var = require("path").var
  ```

  ## Error Handling

  - Use `pcall()` for optional operations that might fail
  - Provide explicit error messages in `error()` calls
  - Guard optional requires:

  ```lua
  local ok, mod = pcall(require, "optional-module")
  if not ok then
    return
  end
  ```

  ## Tables

  - Use `{}` for objects/maps
  - Use `{}` for arrays (Lua uses the same construct)
  - Consistent trailing comma placement
  - Prefer `function()` over `() ->` for clarity

  ## File Locations

  | App | Path |
  |-----|------|
  | Neovim plugins | `modules/home/configurations/neovim/lua/sysinit/plugins/` |
  | Neovim core | `modules/home/configurations/neovim/lua/sysinit/core/` |
  | WezTerm | `modules/home/configurations/wezterm/lua/sysinit/` |
  | Hammerspoon | `modules/darwin/home/hammerspoon/lua/sysinit/` |
  | Sketchybar | `modules/darwin/home/sketchybar/lua/` |

  ## Common Mistakes

  - Forgetting `return M` at end of module
  - Using global variables instead of `local`
  - Missing `pcall` for optional requires
  - Inconsistent indent (must be 2 spaces, not tabs)
  - Putting plugin config in wrong directory
''
