# Architecture: Multi-System Nix Configuration

## High-Level Overview

The refactored flake supports multiple machines with different platforms from a single repository without forcing sequential setup.

```
┌─────────────────────────────────────────────────────────────────┐
│                         flake.nix                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  hostConfigs = {                                                │
│    lv426 = {                                                    │
│      system = "aarch64-darwin"                                  │
│      values = { ... }                                           │
│    };                                                            │
│    arrakis = {                                           │
│      system = "aarch64-linux"                                   │
│      values = { ... }                                           │
│    };                                                            │
│  }                                                               │
│                                                                  │
│  ↓ mkDarwinConfiguration → darwinConfigurations.lv426           │
│  ↓ mkNixosConfiguration → nixosConfigurations.arrakis    │
│  ↓ exports lib for external consumption                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Key Concepts

### 1. Centralized Host Configuration

Instead of external `values.nix`:
```nix
# OLD: values.nix (external file)
{
  user = { username = "rshnbhatia"; hostname = "lv426"; };
  # ...
}

# NEW: In flake.nix under hostConfigs
hostConfigs.lv426 = {
  system = "aarch64-darwin";
  platform = "darwin";
  username = "rshnbhatia";
  values = {
    user = { username = "rshnbhatia"; hostname = "lv426"; };
    # ...
  };
};
```

**Benefits**:
- All hosts in one searchable file
- Clear platform designation
- System mapping explicit
- Configuration validated at parse time

### 2. Builder Functions

Extract common patterns into reusable functions:

```nix
# Build packages for a specific system
mkPkgs = { system, overlays ? [] }:
  import nixpkgs { inherit system overlays; config = {...}; };

# Build utilities
mkUtils = { system, pkgs }:
  import ./modules/lib { inherit lib pkgs system; };

# Process and validate configuration
processValues = { utils, userValues }:
  (lib.evalModules { ... }).config.values;

# Build complete Darwin system
mkDarwinConfiguration = { hostname, values, utils, pkgs, system }:
  darwin.lib.darwinSystem { ... };

# Build complete NixOS system
mkNixosConfiguration = { hostname, values, utils, pkgs, system }:
  lib.nixosSystem { ... };
```

**Benefits**:
- Reusable across multiple hosts
- Type-safe parameter passing
- Encapsulates complexity
- Easily testable logic

### 3. Dynamic Configuration Generation

Instead of static configuration definitions, generate them from hostConfigs:

```nix
# For Darwin
mkConfigurations = f:
  lib.mapAttrs (hostname: hostConfig:
    f {
      inherit hostname;
      system = hostConfig.system;
      values = (processValues { ... }).config.values;
      # ... other args
    }
  ) (lib.filterAttrs (_: cfg: cfg.platform == "darwin") hostConfigs);

darwinConfigurations = mkConfigurations mkDarwinConfiguration;
# Result: { lv426 = <darwin config>, ... }
```

**Benefits**:
- Add new hosts by adding hostConfig entry
- No boilerplate duplication
- Clear relationship between config and output
- Scales to many machines

### 4. Module Organization

```
modules/
├── darwin/                    ← macOS-specific
│   ├── configurations/        ← System configs (dock, aerospace, etc.)
│   ├── packages/              ← Darwin packages
│   └── home-manager.nix       ← Integration with home-manager
│
├── nixos/                     ← NixOS-specific (NEW)
│   ├── configurations/        ← System configs (hardware, gaming, audio)
│   └── (no home-manager here, uses home/ separately)
│
├── home/                      ← Shared across all systems
│   ├── configurations/        ← Home-manager configs (neovim, zsh, etc.)
│   └── packages/              ← Home-manager packages
│
└── lib/                       ← Shared utilities
    ├── values/                ← Schema definitions
    ├── theme/                 ← Theme system
    ├── shell/                 ├─ Aliases, functions, etc.
    ├── validation/            ├─ Value validation
    └── packages/              ├─ Package utilities
```

**Key insight**: `modules/home/` works for both Darwin and NixOS because home-manager is platform-agnostic. Platform-specific configurations live in `modules/darwin/` or `modules/nixos/`.

### 5. Library Exports

The flake exports builder functions for external use:

```nix
lib = {
  # Builders (functions)
  mkDarwinConfiguration = /* ... */;
  mkNixosConfiguration = /* ... */;
  processValues = /* ... */;
  mkPkgs = /* ... */;
  mkUtils = /* ... */;
  mkOverlays = /* ... */;
  
  # Data (for reference)
  hostConfigs = { lv426, arrakis, ... };
  systems = { laptop, desktop, work, ... };
};
```

**Usage in external flake**:
```nix
inputs.personal-sysinit = {
  url = "github:roshbhatia/sysinit";
  inputs.nixpkgs.follows = "nixpkgs";
};

outputs = { personal-sysinit, ... }:
  {
    darwinConfigurations.work-laptop =
      personal-sysinit.lib.mkDarwinConfiguration {
        hostname = "work-laptop";
        values = import ./values.nix;
        # other args built automatically
      };
  };
```

## Data Flow

### Building macOS (lv426)

```
hostConfigs.lv426
    ↓
  (filter for platform == "darwin")
    ↓
  mkOverlays(system)
    ↓
  mkPkgs({system, overlays})
    ↓
  mkUtils({system, pkgs})
    ↓
  processValues({utils, hostConfig.values})
    ↓
  mkDarwinConfiguration({hostname, values, utils, pkgs, system})
    ↓
  darwinConfiguration.lv426 = {
    system.build.toplevel = ...
    system.activationScripts = ...
    home-manager = { ... }
  }
```

### Building NixOS (arrakis)

```
hostConfigs.arrakis
    ↓
  (filter for platform == "linux")
    ↓
  mkOverlays(system)
    ↓
  mkPkgs({system, overlays})
    ↓
  mkUtils({system, pkgs})
    ↓
  processValues({utils, hostConfig.values})
    ↓
  mkNixosConfiguration({hostname, values, utils, pkgs, system})
    ↓
  nixosConfiguration.arrakis = {
    config.system.stateVersion = ...
    config.networking.hostName = ...
    config.boot.* = ...
    config.hardware.* = ...
  }
```

## Schema Validation

Values are validated against a schema defined in `modules/lib/values/default.nix`:

```nix
valuesType = types.submodule {
  options = {
    user = { ... };
    git = { ... };
    darwin = { ... };
    theme = { ... };
    # ... more options
  };
};
```

**When validation happens**:
1. Each host's `values` in `hostConfigs` must conform to `valuesType`
2. `processValues` runs `lib.evalModules` with the schema
3. Invalid configs caught at flake parse time
4. Type mismatches immediately obvious

## Adding a New System

### Example: Add laptop2 (another macOS)

1. Add to `hostConfigs` in `flake.nix`:
```nix
hostConfigs = {
  lv426 = { /* ... */ };
  arrakis = { /* ... */ };
  laptop2 = {
    system = "aarch64-darwin";
    platform = "darwin";
    username = "rshnbhatia";
    values = {
      user = { username = "rshnbhatia"; hostname = "laptop2"; };
      git = { /* same as lv426 or different */ };
      darwin = { /* customize homebrew, etc. */ };
      # ... inherit other values from lv426 or override
    };
  };
};
```

2. Build it:
```bash
nix build ".#darwinConfigurations.laptop2.system"
```

That's it. Everything else is automatic.

## Comparison: Before vs After

### BEFORE
```
File: values.nix (32 lines)
├── User/hostname (1 place to change)
├── Git config (1 place)
└── Darwin config (1 place)

File: flake.nix (170 lines)
├── Single system (aarch64-darwin hardcoded)
└── Linear configuration

Dynamic: No
Multi-system: No (darwin only)
Reusable: No (monolithic)
```

### AFTER
```
File: flake.nix (259 lines)
├── hostConfigs (all machines in one place)
│   ├── lv426 (darwin)
│   └── arrakis (linux)
├── Builder functions (reusable)
├── Dynamic generation (maps hostConfigs to outputs)
└── Library exports (for external use)

Directory: modules/nixos/ (NEW)
├── NixOS-specific configs
└── Ready for arrakis

Dynamic: Yes (add hosts without boilerplate)
Multi-system: Yes (darwin + linux in one flake)
Reusable: Yes (exportable lib for other projects)
```

## Performance Characteristics

- **Evaluation time**: Slightly increased (dynamic generation), minimal impact
- **Build time**: Unchanged (same build processes)
- **Disk space**: Minimal (mostly text restructuring)
- **Scalability**: Linear (each new host adds one hostConfig entry)

## Error Handling

Invalid configuration caught at flake evaluation:
```bash
$ nix eval '.#darwinConfigurations.lv426'
error: user.hostname is required but not set
  at /path/to/flake.nix:42:15
```

This makes configuration errors immediately obvious during development.

---

**Summary**: The refactored architecture trades a small amount of flake complexity for massive gains in configuration manageability, reusability, and extensibility. A single flake now cleanly supports multiple machines, makes adding new systems trivial, and exports a library for external consumption.
