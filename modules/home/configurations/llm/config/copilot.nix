{
  lib,
  pkgs,
  values,
  ...
}:
let
  common = import ../shared/common.nix;

  formatPermissionsForCopilotCli =
    perms:
    let
      allPerms =
        perms.git
        ++ perms.github
        ++ perms.docker
        ++ perms.kubernetes
        ++ perms.nix
        ++ perms.darwin
        ++ perms.navigation
        ++ perms.utilities
        ++ perms.crossplane;

      cleanCmd = cmd: builtins.replaceStrings [ "*" ] [ "" ] cmd;
    in
    {
      allow = map cleanCmd allPerms;
      deny = [ ];
    };

  copilotCliConfig = builtins.toJSON {
    permissions = formatPermissionsForCopilotCli common.commonShellPermissions;
  };

  # MCP server configuration for Copilot CLI
  mcpConfig = builtins.toJSON {
    mcpServers = { };
  };

  configSource = pkgs.writeText "copilot-cli-config" copilotCliConfig;
  mcpSource = pkgs.writeText "copilot-mcp-config" mcpConfig;

  activationScript = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    # Helper function to install writable config
    install_copilot_config() {
      local source_file="$1"
      local dest_path="$2"
      local config_name="$3"

      $DRY_RUN_CMD mkdir -p "$(dirname "$dest_path")"
      if [[ -f "$dest_path" && ! -L "$dest_path" ]]; then
        if ! cmp -s "$source_file" "$dest_path"; then
          $DRY_RUN_CMD echo "Copilot $config_name source changed, backing up and updating"
          $DRY_RUN_CMD cp "$dest_path" "$dest_path.nix-prev"
          $DRY_RUN_CMD cp -f "$source_file" "$dest_path"
        fi
      else
        $DRY_RUN_CMD echo "Installing new writable copilot $config_name"
        if [[ -L "$dest_path" ]]; then
          $DRY_RUN_CMD rm "$dest_path"
        fi
        $DRY_RUN_CMD cp "$source_file" "$dest_path"
      fi
    }

    # Install CLI config to both locations
    install_copilot_config "${configSource}" "''${XDG_CONFIG_HOME:-$HOME/.config}/github-copilot/cli/config.json" "XDG CLI config"
    install_copilot_config "${configSource}" "$HOME/.copilot/config.json" "home CLI config"

    # Install MCP config to both locations
    install_copilot_config "${mcpSource}" "''${XDG_CONFIG_HOME:-$HOME/.config}/github-copilot/cli/mcp-config.json" "XDG MCP config"
    install_copilot_config "${mcpSource}" "$HOME/.copilot/mcp-config.json" "home MCP config"
  '';
in
{
  home.activation = {
    copilotConfig = activationScript;
  };
}
