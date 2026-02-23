# Neovim Config and AI Plugin Repository Split

## Summary

Split the monolithic sysinit repository into two standalone repositories: **sysinit.nvim** (Neovim configuration with Nix integration and curl bootstrap support) and **harness.nvim** (AI terminal orchestration plugin). Both repos support standalone usage while maintaining tight integration with sysinit's system configuration.

## Problem Statement

The current sysinit repository bundles Neovim configuration and AI terminal integration tightly with system-level Nix configuration. This creates several issues:

1. **No portability**: Users can't try the Neovim config without adopting the entire Nix system
2. **No sharing**: The AI terminal plugin can't be used by the broader Neovim community
3. **Tight coupling**: Neovim changes require system rebuilds; hard to iterate quickly
4. **Limited discoverability**: Valuable tools buried in a personal dotfiles repo

## Goals

1. **Dual installation modes**: Support both curl-based bootstrap and Nix-managed installation for sysinit.nvim
2. **Standalone harness.nvim**: Usable by anyone via lazy.nvim, not just sysinit users
3. **Graceful degradation**: Full config works in both Nix and standalone modes with sensible fallbacks
4. **Preserve theme integration**: Nix-managed installs still get dynamic theming from sysinit's theme system
5. **Future-proof**: Architecture supports the upcoming ai-diff-review feature

## Non-Goals

- Porting to other plugin managers (packer, vim-plug) - lazy.nvim only
- Supporting Vim (Neovim-only)
- Backward compatibility with current sysinit structure during transition

## Architecture

### Repository Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         roshbhatia/sysinit                           │
│                    (System-level Nix configuration)                  │
│                                                                      │
│  • Darwin/NixOS system configs                                      │
│  • Home-manager profiles                                            │
│  • Theme system (generates theme_config.json)                       │
│  • Overlays, packages, modules                                      │
└──────────────────────────┬────────────────┬──────────────────────────┘
                           │                │
                  flake input          flake input
                           │                │
                           ▼                ▼
         ┌─────────────────────────┐  ┌──────────────────────┐
         │  roshbhatia/sysinit.nvim │  │  Theme System        │
         │  (Neovim configuration)  │  │  (stays in sysinit)  │
         │                          │  └──────────────────────┘
         │  Two installation modes: │
         │  1. Curl bootstrap       │
         │  2. Nix home-manager     │
         └──────────┬───────────────┘
                    │ lazy.nvim plugin dep
                    ▼
         ┌─────────────────────────┐
         │ roshbhatia/harness.nvim │
         │ (AI terminal plugin)    │
         │                         │
         │  • Agent orchestration  │
         │  • WezTerm/native backends │
         │  • Diff review (future) │
         └──────────┬──────────────┘
                    │ optional deps
                    ▼
         ┌──────────────────────────────┐
         │  snacks.nvim (optional)      │
         │  blink.cmp (optional)        │
         │  nvim-treesitter (optional)  │
         └──────────────────────────────┘
```

### Installation Matrix

| Install Method | Config Managed By | Theme Source | Plugin Updates |
|----------------|-------------------|--------------|----------------|
| `curl \| bash` | Git repo in ~/.config/nvim | Hardcoded default | lazy.nvim sync |
| Nix home-manager | Nix symlinks to store | theme_config.json from sysinit | lazy.nvim sync |

## Components

### 1. sysinit.nvim

**Repository**: `github.com/roshbhatia/sysinit.nvim`

**Structure**:
```
sysinit.nvim/
├── install.sh                     # Curl bootstrap script
├── flake.nix                      # Nix flake exposing home-manager module
├── flake.lock
├── nix/
│   └── hm-module.nix              # Home-manager module wrapper
├── lua/
│   └── sysinit/
│       ├── init.lua               # Main initialization
│       ├── config/
│       │   ├── defaults.lua       # Default theme/settings (curl mode)
│       │   └── nix.lua            # Nix-specific overrides
│       ├── plugins/               # ~80 lazy.nvim plugin specs
│       │   ├── themes.lua         # Theme loader with fallback
│       │   ├── snacks.lua         # Loads harness.nvim
│       │   └── ...
│       ├── lspconfig/             # LSP server configs
│       │   └── markdown_oxide.lua
│       └── utils/
│           ├── env.lua            # Environment detection
│           ├── json_loader.lua    # Load Nix-generated JSON
│           ├── highlight.lua
│           └── yaml_schema.lua
├── after/
│   ├── ftplugin/                  # Filetype-specific settings
│   ├── lsp/                       # Per-LSP configs
│   ├── plugin/                    # After-plugin scripts
│   └── snippets/                  # LuaSnip snippets
├── queries/                       # Treesitter query overrides
├── init.lua                       # Entry point
└── README.md
```

**Key Files**:

#### install.sh
```bash
#!/usr/bin/env bash
set -euo pipefail

REPO="roshbhatia/sysinit.nvim"
NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%s)"

echo "Installing sysinit.nvim..."

# Backup existing config
if [[ -d "$NVIM_CONFIG" ]]; then
  echo "Backing up existing config to $BACKUP_DIR"
  mv "$NVIM_CONFIG" "$BACKUP_DIR"
fi

# Clone repository
git clone --depth 1 "https://github.com/$REPO.git" "$NVIM_CONFIG"

# Remove git history for cleaner state
rm -rf "$NVIM_CONFIG/.git"

echo "Done! Run 'nvim' to complete plugin installation."
echo "Plugins will auto-install on first launch via lazy.nvim."
```

#### lua/sysinit/utils/env.lua
```lua
local M = {}

-- Detect if running under Nix management
function M.is_nix_managed()
  return vim.g.nix_managed == true
end

-- Detect if theme_config.json exists
function M.has_theme_config()
  local config_path = vim.fn.stdpath("config") .. "/theme_config.json"
  return vim.fn.filereadable(config_path) == 1
end

-- Get installation method
function M.get_install_method()
  if M.is_nix_managed() then
    return "nix"
  elseif vim.fn.isdirectory(vim.fn.stdpath("config") .. "/.git") == 1 then
    return "git"
  else
    return "curl"
  end
end

return M
```

#### lua/sysinit/config/defaults.lua
```lua
local M = {}

M.theme = {
  colorscheme = "everforest",
  variant = "dark-hard",
  appearance = "dark",
  transparency = {
    enable = false,
    opacity = 1.0,
    blur = 0,
  },
}

return M
```

#### nix/hm-module.nix
```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.sysinit-nvim;
  
  # Theme config passed from sysinit's theme system
  themeConfig = {
    colorscheme = cfg.theme.colorscheme or "everforest";
    variant = cfg.theme.variant or "dark-hard";
    appearance = cfg.theme.appearance or "dark";
    transparency = cfg.theme.transparency or { enable = false; };
  };
in {
  options.programs.sysinit-nvim = {
    enable = lib.mkEnableOption "sysinit.nvim";
    
    theme = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Theme configuration from sysinit theme system";
    };
    
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra Lua config to append to init.lua";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      viAlias = true;
      withNodeJs = true;
      withPython3 = true;
      
      # Mark as Nix-managed for Lua detection
      initLua = ''
        vim.g.nix_managed = true
        ${cfg.extraConfig}
      '';
    };

    # Symlink config from the flake source
    xdg.configFile = {
      "nvim/init.lua".source = ../init.lua;
      "nvim/lua".source = ../lua;
      "nvim/after".source = ../after;
      "nvim/queries".source = ../queries;
      
      # Nix-generated theme config
      "nvim/theme_config.json".text = builtins.toJSON themeConfig;
    };
  };
}
```

### 2. harness.nvim

**Repository**: `github.com/roshbhatia/harness.nvim`

**Structure**:
```
harness.nvim/
├── lua/
│   └── harness/
│       ├── init.lua               # Main entry, setup()
│       ├── agents.lua             # Agent definitions
│       ├── completion.lua         # Blink.cmp source (optional)
│       ├── context.lua            # Editor state capture
│       ├── file_refresh.lua       # External file change detection
│       ├── history.lua            # Prompt history
│       ├── input.lua              # Multiline input UI
│       ├── keymaps.lua            # Keymap generation
│       ├── picker.lua             # Agent picker
│       ├── placeholders.lua       # +file, +selection, +diagnostic
│       ├── session.lua            # Terminal session manager
│       ├── terminal.lua           # Send utilities
│       ├── review/                # AI diff review (future)
│       │   ├── init.lua
│       │   ├── queue.lua
│       │   ├── ui.lua
│       │   └── rpc.lua
│       └── backends/
│           ├── native.lua         # vim.fn.termopen / Snacks fallback
│           └── wezterm.lua        # WezTerm CLI backend
├── plugin/
│   └── harness.lua                # Auto-setup if no explicit setup()
├── doc/
│   └── harness.txt                # Vimdoc
├── README.md
├── LICENSE
└── .github/
    └── workflows/
        └── ci.yml                 # Test against Neovim stable/nightly
```

**Key Files**:

#### lua/harness/init.lua
```lua
local M = {}

function M.setup(opts)
  opts = opts or {}
  
  local agents = require("harness.agents")
  local session = require("harness.session")
  local completion = require("harness.completion")
  local file_refresh = require("harness.file_refresh")
  
  -- Override default agents if provided
  if opts.agents then
    agents.set_custom(opts.agents)
  end
  
  -- Build terminals config from available agents
  local terminals_config = {}
  for _, agent in ipairs(agents.get_all()) do
    terminals_config[agent.name] = {
      cmd = agent.full_cmd,
    }
  end
  
  session.setup({
    terminals = terminals_config,
    env = opts.env or {},
  })
  
  completion.setup(opts.completion or {})
  
  file_refresh.setup(opts.file_refresh or {
    enable = true,
    timer_interval = 1000,
    updatetime = 100,
  })
  
  -- Future: review module
  if opts.review and opts.review.enable then
    require("harness.review").setup(opts.review)
  end
end

return M
```

#### lua/harness/picker.lua (with snacks fallback)
```lua
local M = {}

local function has_snacks()
  return pcall(require, "snacks")
end

function M.pick_agent(callback)
  local agents = require("harness.agents")
  local available = agents.get_all()
  
  if has_snacks() then
    local snacks = require("snacks")
    snacks.picker.pick({
      items = available,
      format = function(item)
        return {
          text = item.name,
          item = item,
        }
      end,
      confirm = function(item)
        callback(item.name)
      end,
    })
  else
    -- Fallback to vim.ui.select
    local choices = vim.tbl_map(function(agent) return agent.name end, available)
    vim.ui.select(choices, {
      prompt = "Select AI agent:",
    }, function(choice)
      if choice then callback(choice) end
    end)
  end
end

return M
```

**Plugin Spec Example** (for users):
```lua
{
  "roshbhatia/harness.nvim",
  dependencies = {
    { "folke/snacks.nvim", optional = true },
    { "saghen/blink.cmp", optional = true },
    { "nvim-treesitter/nvim-treesitter", optional = true },
  },
  opts = {
    agents = {
      -- Override or extend default agents
      custom = {
        name = "custom-llm",
        cmd = "custom-llm-cli",
        description = "My custom LLM",
      },
    },
    env = {
      PAGER = "bat",
    },
    file_refresh = {
      enable = true,
      timer_interval = 1000,
    },
    review = {
      enable = false,  -- Future feature
    },
  },
  keys = function()
    return require("harness.keymaps").generate_all()
  end,
}
```

### 3. Updated sysinit Integration

**flake.nix changes**:
```nix
{
  inputs = {
    sysinit-nvim.url = "github:roshbhatia/sysinit.nvim";
    # harness.nvim is consumed via lazy.nvim, not as a flake input
    # ... existing inputs
  };

  outputs = { self, sysinit-nvim, ... }: {
    # Import sysinit-nvim's home-manager module
    # Pass theme config from sysinit's theme system
  };
}
```

**modules/home/programs/neovim/default.nix** (becomes thin wrapper):
```nix
{ config, ... }:
{
  imports = [ inputs.sysinit-nvim.homeManagerModules.default ];
  
  programs.sysinit-nvim = {
    enable = true;
    theme = {
      inherit (config.sysinit.theme) colorscheme variant appearance transparency;
    };
  };
}
```

## Implementation Phases

### Phase 1: Create sysinit.nvim Repository

**Effort**: 4-6 hours

**Tasks**:
- [ ] Create `github.com/roshbhatia/sysinit.nvim` repository
- [ ] Copy Lua config structure (excluding `utils/ai/`)
- [ ] Create `lua/sysinit/utils/env.lua` for environment detection
- [ ] Create `lua/sysinit/config/defaults.lua` for fallback theme
- [ ] Update `lua/sysinit/plugins/themes.lua` to use fallback logic
- [ ] Create `install.sh` bootstrap script
- [ ] Create `flake.nix` and `nix/hm-module.nix`
- [ ] Update all internal require paths
- [ ] Add harness.nvim as lazy.nvim plugin dependency
- [ ] Write comprehensive README with both install methods
- [ ] Test curl bootstrap on fresh VM
- [ ] Test Nix integration with `nix flake check`

**Deliverables**:
- Working sysinit.nvim repository
- One-liner curl install: `curl -sL https://raw.githubusercontent.com/roshbhatia/sysinit.nvim/main/install.sh | bash`
- Nix flake with `homeManagerModules.default`

### Phase 2: Create harness.nvim Repository

**Effort**: 3-4 hours

**Tasks**:
- [ ] Create `github.com/roshbhatia/harness.nvim` repository
- [ ] Extract `modules/home/programs/neovim/lua/sysinit/utils/ai/` as `lua/harness/`
- [ ] Update all require paths: `sysinit.utils.ai.*` → `harness.*`
- [ ] Create `lua/harness/init.lua` with `setup()` function
- [ ] Add Snacks.nvim fallbacks (vim.ui.select, vim.fn.termopen)
- [ ] Add blink.cmp optional integration
- [ ] Add nvim-treesitter optional integration
- [ ] Create `plugin/harness.lua` for auto-setup
- [ ] Write vimdoc (`doc/harness.txt`)
- [ ] Write comprehensive README with usage examples
- [ ] Add GitHub Actions CI (test on Neovim stable/nightly)
- [ ] Test standalone with minimal config (no sysinit.nvim)

**Deliverables**:
- Working harness.nvim plugin
- Published on GitHub
- Usable via lazy.nvim by any Neovim user

### Phase 3: Update sysinit to Consume New Repos

**Effort**: 2-3 hours

**Tasks**:
- [ ] Add `sysinit-nvim` as flake input in `flake.nix`
- [ ] Refactor `modules/home/programs/neovim/default.nix` to use sysinit-nvim module
- [ ] Pass theme config from `config.sysinit.theme` to `programs.sysinit-nvim.theme`
- [ ] Remove extracted Lua code from sysinit (both neovim and ai utils)
- [ ] Update `modules/lib/theme/adapters/neovim.nix` if needed
- [ ] Test full system rebuild: `nix flake check`
- [ ] Test full system switch: `nh os switch`
- [ ] Verify theme integration still works
- [ ] Verify harness.nvim loads and works via WezTerm backend
- [ ] Update sysinit README to reference the new repos

**Deliverables**:
- sysinit consumes sysinit.nvim and harness.nvim
- All existing functionality preserved
- Cleaner separation of concerns

### Phase 4: Future - AI Diff Review Integration

**Effort**: 8-12 hours (separate from this plan)

**Tasks**:
- [ ] Implement `lua/harness/review/` module in harness.nvim
- [ ] Add IPC with ai-sandbox-fuse daemon
- [ ] Integrate with CodeDiff for UI
- [ ] Update keymap generation for review bindings
- [ ] Test end-to-end with OpenCode, Claude, Goose

**Reference**: See `.openspec/features/ai-diff-review/spec.md`

## Graceful Degradation Matrix

| Feature | Nix Managed | Curl Bootstrap | Notes |
|---------|-------------|----------------|-------|
| Theme configuration | JSON from sysinit theme system | Hardcoded `everforest dark-hard` | Same plugin code, different data source |
| lazy.nvim plugins | Auto-install on first launch | Auto-install on first launch | Identical behavior |
| harness.nvim | Available via lazy.nvim | Available via lazy.nvim | Identical behavior |
| LSP servers | mason.nvim auto-install | mason.nvim auto-install | Identical behavior |
| Treesitter parsers | Auto-install | Auto-install | Identical behavior |
| Nix-specific paths | Applied via `vim.g.nix_managed` | Skipped | e.g., Nix store paths |
| Theme hot-reload | `nh os switch` rebuilds JSON | Manual edit of defaults.lua | Different workflow |
| Config updates | `nix flake update sysinit-nvim` | `git pull` in ~/.config/nvim | Different workflow |

## Testing Strategy

### Curl Bootstrap Tests

1. **Fresh install on VM**:
   ```bash
   # On Ubuntu/Debian/Fedora VM
   curl -sL https://raw.githubusercontent.com/roshbhatia/sysinit.nvim/main/install.sh | bash
   nvim  # Verify lazy.nvim auto-installs plugins
   ```

2. **Verify theme fallback**:
   - Check `everforest` colorscheme applied
   - No errors about missing `theme_config.json`

3. **Verify harness.nvim works**:
   - `<leader>jj` opens agent picker
   - Native backend (vim.fn.termopen) works
   - Placeholders (+file, +selection) work

### Nix Integration Tests

1. **Flake check**:
   ```bash
   cd sysinit.nvim
   nix flake check
   ```

2. **Home-manager integration**:
   ```bash
   cd sysinit
   nh os build
   nh os switch
   nvim  # Verify theme from sysinit.theme applied
   ```

3. **Verify theme passthrough**:
   - Change `sysinit.theme.colorscheme` in sysinit
   - Rebuild
   - Verify Neovim picks up new theme from JSON

### harness.nvim Standalone Tests

1. **Minimal config test**:
   ```lua
   -- init.lua
   require("lazy").setup({
     { "roshbhatia/harness.nvim", opts = {} }
   })
   ```

2. **Test without Snacks.nvim**:
   - Verify vim.ui.select fallback works
   - Verify native terminal backend works

3. **Test without blink.cmp**:
   - Verify no errors on completion attempt
   - Verify graceful degradation

## Migration Checklist

### sysinit.nvim
- [ ] Repository created
- [ ] install.sh tested on fresh VM
- [ ] Nix flake structure working
- [ ] Theme fallback tested
- [ ] README written with both install methods
- [ ] GitHub repository published

### harness.nvim
- [ ] Repository created
- [ ] All require paths updated
- [ ] Snacks.nvim fallbacks implemented
- [ ] Standalone test successful
- [ ] Vimdoc written
- [ ] README written
- [ ] GitHub repository published
- [ ] CI workflow added

### sysinit integration
- [ ] Flake inputs updated
- [ ] neovim module refactored
- [ ] Theme passthrough working
- [ ] Old code removed
- [ ] Full system rebuild successful
- [ ] README updated with links to new repos

## Success Criteria

1. **Curl bootstrap works**: Any user can run one command and get working config
2. **Nix integration preserved**: sysinit users get dynamic theming and declarative management
3. **harness.nvim is portable**: Works as a standalone plugin in any Neovim config
4. **No functionality lost**: All current features work in the new architecture
5. **Documentation clear**: Both repos have comprehensive READMEs
6. **Tests pass**: CI for harness.nvim, manual testing for both install methods

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Breaking sysinit users during migration | Test each phase independently; keep old structure until cutover |
| Theme integration breaks | Keep theme adapter in sysinit; test JSON generation thoroughly |
| harness.nvim Snacks fallback incomplete | Implement and test vim.ui.select path before extraction |
| Curl bootstrap fails on some systems | Test on multiple distros (Ubuntu, Fedora, Arch, macOS) |
| Git history loss in curl install | Acceptable tradeoff for cleaner user experience |
| Dependency version conflicts | Pin lazy.nvim lockfile; document known compatible versions |

## Open Questions

1. **Neovim nightly overlay**: Should this move to sysinit.nvim or stay in sysinit?
   - **Decision**: Keep in sysinit (system-level concern, not all users want nightly)

2. **Theme adapter location**: Keep `modules/lib/theme/adapters/neovim.nix` in sysinit or move to sysinit.nvim?
   - **Decision**: Keep in sysinit, pass generated config to sysinit.nvim module

3. **Version pinning**: Should sysinit pin specific versions of sysinit.nvim and harness.nvim?
   - **Decision**: Yes, use flake.lock for reproducibility; update manually

4. **Git integration**: `modules/home/programs/git/default.nix` references nvim for diff/merge
   - **Decision**: No change needed - just references `nvim` binary, not config

5. **Backward compatibility**: Support old structure for a transition period?
   - **Decision**: No - clean break is simpler, users can stay on old commit if needed

## References

- [lazy.nvim plugin spec](https://github.com/folke/lazy.nvim)
- [Home-manager modules](https://nix-community.github.io/home-manager/)
- [Neovim plugin development best practices](https://github.com/nanotee/nvim-lua-guide)
- AI Diff Review feature spec: `.openspec/features/ai-diff-review/spec.md`
