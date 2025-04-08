{ pkgs, lib, ... }:
{
  home.file = {
    ".local/bin/merge-vscode-configs".source = pkgs.writeShellScript "merge-vscode-configs" ''
      merge_config() {
        local config_name="$1"
        TARGET="$HOME/Library/Application Support/Code/User/$config_name"
        SOURCE="${toString ./.}/config/$config_name"
        
        if [ ! -f "$SOURCE" ]; then
          echo "🔧 Error: Source file $config_name not found at $SOURCE"
          return 1
        fi
        
        echo "🔧 Merging VSCode $config_name..."
        
        if [ ! -f "$TARGET" ]; then
          echo "🔧 Target $config_name doesn't exist, creating new file..."
          cp "$SOURCE" "$TARGET"
        else
          echo "🔧 Merging existing $config_name with new configuration..."
          if ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$TARGET" "$SOURCE" > "$TARGET.tmp"; then
            mv "$TARGET.tmp" "$TARGET"
            echo "🔧 Successfully merged $config_name"
          else
            echo "🔧 Error merging $config_name"
            rm -f "$TARGET.tmp"
            return 1
          fi
        fi
      }

      # Create config directory if it doesn't exist
      mkdir -p "$HOME/Library/Application Support/Code/User"
      
      # Merge both configuration files
      merge_config "settings.json"
      merge_config "keybindings.json"
    '';
  };

  # Run the merge script during activation
  home.activation.mergeVscodeConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD $HOME/.local/bin/merge-vscode-configs
  '';
}