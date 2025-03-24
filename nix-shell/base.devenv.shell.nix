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
      
      # Function to safely source a file if it exists
      source_if_exists() {
        if [ -f "$1" ]; then
          source "$1"
        fi
      }
      
      # Source all zsh utility scripts from extras directory
      if [ -d "$HOME/.config/zsh/extras" ]; then
        # First, ensure loglib.sh is loaded
        source_if_exists "$HOME/.config/zsh/extras/loglib.sh"
        
        # Then load all other utility modules
        for module in "$HOME/.config/zsh/extras/"*.sh; do
          if [ -f "$module" ] && [ "$module" != "$HOME/.config/zsh/extras/loglib.sh" ]; then
            source "$module"
          fi
        done
        
        # Source zsh-specific utility files
        for module in "$HOME/.config/zsh/extras/"*.zsh; do
          if [ -f "$module" ]; then
            source "$module"
          fi
        done
        
        echo "✅ Loaded zsh utility scripts from $HOME/.config/zsh/extras"
      fi
    '';
}