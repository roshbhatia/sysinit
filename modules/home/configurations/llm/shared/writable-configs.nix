# modules/home/configurations/llm/shared/writable-configs.nix
#
# Purpose: Helper functions for creating writable configuration files for LLM tools.
# Many LLM tools (goose, claude, etc.) need to mutate their config files at runtime.
# This module provides utilities to:
# 1. Write initial config to Nix store (via pkgs.writeText)
# 2. Copy to writable location during home-manager activation
# 3. Only overwrite if source changed (preserves user edits when possible)
{
  lib,
  pkgs,
}:
let
  inherit (lib) hm;

  # Creates a writable config file setup
  # Returns an attribute set with:
  # - source: path to source file in Nix store
  # - activation: home.activation entry (copies to writable location)
  #
  # Parameters:
  # - path: config path relative to XDG_CONFIG_HOME (e.g., "goose/config.yaml")
  # - text: content of the config file
  # - executable: whether file should be executable (default: false)
  # - force: whether to force overwrite on every activation (default: false)
  mkWritableConfig =
    {
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

      # Backup suffix for preserving existing files
      backupSuffix = ".nix-prev";

      # Script to copy file to writable location
      # Uses $XDG_CONFIG_HOME environment variable at runtime
      copyScript =
        if force then
          # Force mode: always overwrite
          ''
            DEST_PATH="''${XDG_CONFIG_HOME:-$HOME/.config}/${path}"
            $DRY_RUN_CMD mkdir -p "$(dirname "$DEST_PATH")"
            $DRY_RUN_CMD echo "Installing writable config: ${path}"
            if [[ -f "$DEST_PATH" && ! -L "$DEST_PATH" ]]; then
              # Make backup file writable if it exists (prevents permission errors)
              [[ -f "$DEST_PATH${backupSuffix}" ]] && $DRY_RUN_CMD chmod u+w "$DEST_PATH${backupSuffix}"
              $DRY_RUN_CMD cp "$DEST_PATH" "$DEST_PATH${backupSuffix}"
            fi
            $DRY_RUN_CMD cp -f "${sourceFile}" "$DEST_PATH"
            ${if executable then ''$DRY_RUN_CMD chmod +x "$DEST_PATH"'' else ""}
          ''
        else
          # Smart mode: only update if source changed
          ''
            DEST_PATH="''${XDG_CONFIG_HOME:-$HOME/.config}/${path}"
            $DRY_RUN_CMD mkdir -p "$(dirname "$DEST_PATH")"

            # Check if destination exists and is not a symlink
            if [[ -f "$DEST_PATH" && ! -L "$DEST_PATH" ]]; then
              # File exists - check if source changed
              if ! cmp -s "${sourceFile}" "$DEST_PATH"; then
                $DRY_RUN_CMD echo "Config source changed, backing up and updating: ${path}"
                # Make backup file writable if it exists (prevents permission errors)
                [[ -f "$DEST_PATH${backupSuffix}" ]] && $DRY_RUN_CMD chmod u+w "$DEST_PATH${backupSuffix}"
                $DRY_RUN_CMD cp "$DEST_PATH" "$DEST_PATH${backupSuffix}"
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

      # Activation script to copy file
      activation = hm.dag.entryAfter [ "linkGeneration" ] copyScript;
    };

  # Convenience function to create multiple writable configs
  # Returns attribute sets for xdg.configFile and home.activation
  mkWritableConfigs =
    configs:
    let
      results = builtins.map mkWritableConfig configs;
    in
    {
      activations = builtins.listToAttrs (
        lib.imap0 (i: result: {
          name = "writable-config-${toString i}";
          value = result.activation;
        }) results
      );
    };
in
{
  inherit mkWritableConfig mkWritableConfigs;
}
