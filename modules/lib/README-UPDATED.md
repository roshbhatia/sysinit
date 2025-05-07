# Sysinit Activation Framework (Updated)

This directory contains the core library functions for managing system activation scripts in a consistent way.

## Architecture Overview

The activation framework is designed to solve two key problems:

1. Ensuring PATH is properly set before running any activation commands
2. Providing consistent logging across all activation scripts

### Core Components

- **`activation-utils.nix`**: The main utility library that provides PATH management and logging functions
  - `mkActivationUtils`: Sets up the PATH and logging functions (must run before all other activations)
  - `mkPackageManager`: Creates package manager activation scripts
  - `mkActivationScript`: Creates custom activation scripts

## Important Changes

The latest version now properly handles multiple activation scripts by returning only the activation script configuration, not the entire `home.activation` attribute. This fixes the type mismatch errors that occurred when multiple modules defined activation scripts.

## How to Use

### Setting Up

The activation framework is automatically set up by `modules/darwin/activation.nix`. This ensures that all required utilities are available before any other activation scripts run.

### Package Managers

To create a new package manager configuration:

```nix
{ pkgs, lib, config, userConfig ? {}, ... }:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
in {
  home.activation.yourManagerPackages = activationUtils.mkPackageManager {
    name = "yourpackagemanager";
    basePackages = [
      "package1"
      "package2"
    ];
    additionalPackages = if userConfig ? yourpackagemanager && userConfig.yourpackagemanager ? additionalPackages
      then userConfig.yourpackagemanager.additionalPackages
      else [];
    executableArguments = [ "install" "--your-flags" ];
    executablePath = "yourpackagemanager";  # Will use PATH to find this
    skipIfMissing = true;     # Optional: Skip if executable is not found
    logFailures = false;      # Optional: Don't fail entire activation if package install fails
  };
}
```

### Custom Activation Scripts

For custom activation scripts:

```nix
{ pkgs, lib, config, userConfig ? {}, ... }:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
in {
  home.activation.yourCustomScript = activationUtils.mkActivationScript {
    description = "Your custom activation description";
    requiredExecutables = [ "command1" "command2" ];
    script = ''
      # Your script here
      log_info "Doing something important..."
      
      # Use log_command for commands that might fail
      log_command "your-command --with args" "Running your command"
      
      # Check results and log appropriately
      if [ -f "/path/to/file" ]; then
        log_success "File exists!"
      else
        log_error "File does not exist!"
      fi
    '';
    after = [ "setupActivationUtils" "writeBoundary" ];  # Optional: Specify dependencies
  };
}
```

## Available Logging Functions

The following logging functions are available in all activation scripts:

- `log_info "message"`: Log an informational message
- `log_debug "message"`: Log a debug message
- `log_error "message"`: Log an error message
- `log_success "message"`: Log a success message
- `log_command "command" "description"`: Run a command and log its result
- `check_executable "executable"`: Check if an executable exists in PATH

## PATH Management

The activation framework sets up a consistent PATH environment that includes common directories. You can add additional paths through userConfig:

```nix
# Example configuration
{
  additionalPaths = [
    "$HOME/.custom/bin"
    "/opt/custom/bin"
  ];
}
```
