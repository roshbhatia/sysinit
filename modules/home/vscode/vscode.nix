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
        
        # Ensure target directory exists with proper permissions
        mkdir -p "$(dirname "$TARGET")"
        
        if [ ! -f "$TARGET" ]; then
          echo "🔧 Target $config_name doesn't exist, creating new file..."
          cp "$SOURCE" "$TARGET"
          chmod 644 "$TARGET"
        else
          echo "🔧 Merging existing $config_name with new configuration..."
          # Ensure the target is writable before we start
          chmod 644 "$TARGET"
          
          if [ "$config_name" = "keybindings.json" ]; then
            # For keybindings.json, concatenate arrays
            if ! ${pkgs.yq}/bin/yq -e 'type == "array"' "$TARGET" >/dev/null 2>&1; then
              echo "🔧 Error: Target $config_name is not a valid JSON array"
              return 1
            fi
            if ! ${pkgs.yq}/bin/yq -e 'type == "array"' "$SOURCE" >/dev/null 2>&1; then
              echo "🔧 Error: Source $config_name is not a valid JSON array"
              return 1
            fi
            
            # Merge arrays with yq and preserve comments and formatting
            if ${pkgs.yq}/bin/yq ea '. as $item ireduce ({}; . * $item )' "$TARGET" "$SOURCE" > "$TARGET.tmp"; then
              mv -f "$TARGET.tmp" "$TARGET"
              chmod 644 "$TARGET"
              echo "🔧 Successfully merged $config_name"
            else
              echo "🔧 Error merging $config_name"
              rm -f "$TARGET.tmp"
              return 1
            fi
          else
            # For settings.json, merge objects and preserve comments
            if ${pkgs.yq}/bin/yq ea '. as $item ireduce ({}; . * $item )' "$TARGET" "$SOURCE" > "$TARGET.tmp"; then
              mv -f "$TARGET.tmp" "$TARGET"
              chmod 644 "$TARGET"
              echo "🔧 Successfully merged $config_name"
            else
              echo "🔧 Error merging $config_name"
              rm -f "$TARGET.tmp"
              return 1
            fi
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