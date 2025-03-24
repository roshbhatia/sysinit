# This is a nix-shell env that should be used as a base.
{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    nativeBuildInputs = with pkgs.buildPackages; [ 
      go_1_24
      macchina
    ];
    
    shellHook = ''
      # Show system info
      macchina --theme nix
      
      # Function to safely source a file if it exists and doesn't have the ignore marker
      source_if_valid() {
        if [ -f "$1" ]; then
          # Check if the file contains the ignore marker
          if ! grep -q "# sysinit.nix-shell::ignore" "$1"; then
            source "$1"
            return 0
          else
            echo "⏭️  Skipping $1 (has ignore marker)"
            return 1
          fi
        fi
        return 1
      }
      
      # Source all zsh utility scripts from extras directory
      if [ -d "$HOME/.config/zsh/extras" ]; then
        # Count how many files we actually sourced
        sourced_count=0
        
        # First, ensure loglib.sh is loaded
        if source_if_valid "$HOME/.config/zsh/extras/loglib.sh"; then
          sourced_count=$((sourced_count + 1))
        fi
        
        # Then load all other utility modules
        for module in "$HOME/.config/zsh/extras/"*.sh; do
          if [ -f "$module" ] && [ "$module" != "$HOME/.config/zsh/extras/loglib.sh" ]; then
            if source_if_valid "$module"; then
              sourced_count=$((sourced_count + 1))
            fi
          fi
        done
        
        # Source zsh-specific utility files
        for module in "$HOME/.config/zsh/extras/"*.zsh; do
          if [ -f "$module" ]; then
            if source_if_valid "$module"; then
              sourced_count=$((sourced_count + 1))
            fi
          fi
        done
        
        echo "✅ Loaded $sourced_count zsh utility scripts from $HOME/.config/zsh/extras"
      fi
    '';
}