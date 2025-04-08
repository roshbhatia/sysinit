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
        
        # Ensure target directory exists
        mkdir -p "$(dirname "$TARGET")"
        
        # Create target file if it doesn't exist
        if [ ! -f "$TARGET" ]; then
          echo "🔧 Target $config_name doesn't exist, creating new file..."
          cp "$SOURCE" "$TARGET"
        fi

        # Ensure proper permissions
        chmod 644 "$TARGET" 2>/dev/null || sudo chmod 644 "$TARGET"
        
        echo "🔧 Merging existing $config_name with new configuration..."
        
        if [ "$config_name" = "keybindings.json" ]; then
          # For keybindings.json, ensure both files are valid JSON arrays
          if ! ${pkgs.jq}/bin/jq -e 'type == "array"' "$TARGET" >/dev/null 2>&1; then
            echo "[]" > "$TARGET"
          fi
          
          # Merge arrays with jq
          if ${pkgs.jq}/bin/jq -s '[.[0] + .[1] | unique]' "$TARGET" "$SOURCE" > "$TARGET.tmp"; then
            mv -f "$TARGET.tmp" "$TARGET"
            chmod 644 "$TARGET" 2>/dev/null || sudo chmod 644 "$TARGET"
            echo "🔧 Successfully merged $config_name"
          else
            echo "🔧 Error merging $config_name"
            rm -f "$TARGET.tmp"
            return 1
          fi
        else
          # For settings.json, merge objects with jq
          if ${pkgs.jq}/bin/jq -s 'reduce .[] as $item ({}; . * $item)' "$TARGET" "$SOURCE" > "$TARGET.tmp"; then
            mv -f "$TARGET.tmp" "$TARGET"
            chmod 644 "$TARGET" 2>/dev/null || sudo chmod 644 "$TARGET"
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