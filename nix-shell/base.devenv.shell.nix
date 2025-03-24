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
      
      # Source all zsh utility scripts from extras directory
      if [[ -d "$HOME/.config/zsh/extras" ]]; then
        # First, ensure loglib.sh is loaded
        if [[ -f "$HOME/.config/zsh/extras/loglib.sh" ]]; then
          source "$HOME/.config/zsh/extras/loglib.sh"
        fi
        
        # Then load all other utility modules
        for module in $HOME/.config/zsh/extras/*.sh; do
          if [[ -f "$module" && "$module" != "$HOME/.config/zsh/extras/loglib.sh" ]]; then
            source "$module"
          fi
        done
        
        # Source zsh-specific utility files
        for module in $HOME/.config/zsh/extras/*.zsh; do
          if [[ -f "$module" ]]; then
            source "$module"
          fi
        done
        
        echo "✅ Loaded zsh utility scripts from $HOME/.config/zsh/extras"
      fi
    '';
}