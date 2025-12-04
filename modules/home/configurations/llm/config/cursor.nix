{
  lib,
  pkgs,
  config,
  ...
}:
let
  common = import ../shared/common.nix;

  cursorConfig = builtins.toJSON {
    version = 1;
    permissions = {
      allow = common.formatPermissionsForCursor common.commonShellPermissions;
      deny = [ ];
    };
    editor = {
      vimMode = true;
    };
    network = {
      useHttp1ForAgent = true;
    };
  };

  # Source file in Nix store
  sourceFile = pkgs.writeText "cursor-cli-config" cursorConfig;

  # Activation script for both locations
  activationScript = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    # Helper function to install writable config
    install_cursor_config() {
      local source_file="$1"
      local dest_path="$2"
      local config_name="$3"
      
      $DRY_RUN_CMD mkdir -p "$(dirname "$dest_path")"
      if [[ -f "$dest_path" && ! -L "$dest_path" ]]; then
        if ! cmp -s "$source_file" "$dest_path"; then
          $DRY_RUN_CMD echo "Cursor $config_name source changed, backing up and updating"
          $DRY_RUN_CMD cp "$dest_path" "$dest_path.nix-prev"
          $DRY_RUN_CMD cp -f "$source_file" "$dest_path"
        fi
      else
        $DRY_RUN_CMD echo "Installing new writable cursor $config_name"
        if [[ -L "$dest_path" ]]; then
          $DRY_RUN_CMD rm "$dest_path"
        fi
        $DRY_RUN_CMD cp "$source_file" "$dest_path"
      fi
    }

    # Install to both XDG and home directory locations
    install_cursor_config "${sourceFile}" "''${XDG_CONFIG_HOME:-$HOME/.config}/cursor/cli-config.json" "XDG config"
    install_cursor_config "${sourceFile}" "$HOME/.cursor/cli-config.json" "home config"
  '';
in
{
  home.activation.cursorConfig = activationScript;
}
