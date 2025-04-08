{ pkgs, lib, ... }:
{
  home.file = {
    # Overwrite keybindings.json
    "Library/Application Support/Code/User/keybindings.json".source = ./config/keybindings.json;
    
    # For settings.json, we'll use a script to merge
    ".local/bin/merge-vscode-settings".source = pkgs.writeShellScript "merge-vscode-settings" ''
      TARGET="$HOME/Library/Application Support/Code/User/settings.json"
      SOURCE="${./config/settings.json}"
      
      if [ ! -f "$TARGET" ]; then
        cp "$SOURCE" "$TARGET"
      else
        # Merge settings, preferring target's existing values
        ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$TARGET" "$SOURCE" > "$TARGET.tmp"
        mv "$TARGET.tmp" "$TARGET"
      fi
    '';
  };

  # Run the merge script during activation
  home.activation.mergeVscodeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD $HOME/.local/bin/merge-vscode-settings
  '';
}