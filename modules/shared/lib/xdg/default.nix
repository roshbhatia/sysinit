# modules/shared/lib/xdg/default.nix
#
# Purpose: Utilities for creating writable XDG configuration files.
# Many tools (LLM agents, IDEs, etc.) need to mutate their config files at runtime.
# This module provides utilities to:
# 1. Write initial config to Nix store (via pkgs.writeText)
# 2. Copy to writable XDG location during home-manager activation
# 3. Only overwrite if source changed (preserves user edits when possible)
# 4. Clean up legacy backup files (.nix-prev, .bak, .backup)
{
  lib,
  pkgs,
}:
let
  # Creates a writable XDG config file setup
  # Returns an attribute set with:
  # - source: path to source file in Nix store
  # - script: activation script (caller wraps with hm.dag.entryAfter)
  #
  # Parameters:
  # - config: home-manager config object (to access xdg.configHome)
  # - path: config path relative to XDG_CONFIG_HOME (e.g., "goose/config.yaml")
  # - text: content of the config file
  # - executable: whether file should be executable (default: false)
  # - force: whether to force overwrite on every activation (default: false)
  mkWritableXdgConfig =
    {
      config,
      path,
      text,
      executable ? false,
      force ? false,
    }:
    let
      # Generate unique name for this config
      activationName = "writable-${builtins.replaceStrings [ "/" "." ] [ "-" "-" ] path}";

      # Create source file in Nix store
      sourceFile = pkgs.writeText "${activationName}-source" text;

      # Get XDG config home from home-manager configuration
      xdgConfigHome = config.xdg.configHome;

      # Script to copy file to writable location
      copyScript =
        if force then
          # Force mode: always overwrite
          ''
            DEST_PATH="${xdgConfigHome}/${path}"
            $DRY_RUN_CMD mkdir -p "$(dirname "$DEST_PATH")"
            $DRY_RUN_CMD echo "Installing writable config: ${path}"

            # Remove legacy backup files
            for backup_ext in .nix-prev .bak .backup; do
              [[ -f "$DEST_PATH$backup_ext" ]] && $DRY_RUN_CMD rm -f "$DEST_PATH$backup_ext"
            done

            $DRY_RUN_CMD cp -f "${sourceFile}" "$DEST_PATH"
            ${if executable then ''$DRY_RUN_CMD chmod +x "$DEST_PATH"'' else ""}
          ''
        else
          # Smart mode: only update if source changed
          ''
            DEST_PATH="${xdgConfigHome}/${path}"
            $DRY_RUN_CMD mkdir -p "$(dirname "$DEST_PATH")"

            # Remove legacy backup files
            for backup_ext in .nix-prev .bak .backup; do
              [[ -f "$DEST_PATH$backup_ext" ]] && $DRY_RUN_CMD rm -f "$DEST_PATH$backup_ext"
            done

            # Check if destination exists and is not a symlink
            if [[ -f "$DEST_PATH" && ! -L "$DEST_PATH" ]]; then
              # File exists - check if source changed
              if ! cmp -s "${sourceFile}" "$DEST_PATH"; then
                $DRY_RUN_CMD echo "Config source changed, updating: ${path}"
                $DRY_RUN_CMD cp -f "${sourceFile}" "$DEST_PATH"
                ${if executable then ''$DRY_RUN_CMD chmod +x "$DEST_PATH"'' else ""}
              else
                $DRY_RUN_CMD echo "Config unchanged, preserving: ${path}"
              fi
            else
              # First install or was a symlink
              $DRY_RUN_CMD echo "Installing new writable config: ${path}"
              if [[ -L "$DEST_PATH" ]]; then
                $DRY_RUN_CMD rm "$DEST_PATH"
              fi
              $DRY_RUN_CMD cp "${sourceFile}" "$DEST_PATH"
              ${if executable then ''$DRY_RUN_CMD chmod +x "$DEST_PATH"'' else ""}
            fi
          '';
    in
    {
      # Store the source file path for reference
      source = sourceFile;

      # Return raw script - caller wraps with hm.dag.entryAfter
      script = copyScript;
    };

  # Convenience function to create multiple writable configs
  # Returns attribute sets for home.activation
  mkWritableXdgConfigs =
    configs:
    let
      results = builtins.map mkWritableXdgConfig configs;
    in
    {
      activations = builtins.listToAttrs (
        lib.imap0 (i: result: {
          name = "writable-config-${toString i}";
          value = result.script;
        }) results
      );
    };
in
{
  inherit mkWritableXdgConfig mkWritableXdgConfigs;
}
