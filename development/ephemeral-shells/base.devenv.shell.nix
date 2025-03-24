# Base devenv.shell.nix template - Automatically used by devenv.init
#
# This provides:
# - Shell detection (ZSH, Nushell, Bash)
# - Automatic alias configuration
# - Script loading from zsh/extras directory
# - Consistent development environment

{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    # Add your project's build inputs and dependencies here
    nativeBuildInputs = with pkgs.buildPackages; [ 
      # Core tools
      macchina
      
      # Development tooling
      nixpkgs-fmt
      jq
      ripgrep
      fd
      fzf
      yazi
      eza
      atuin
    ];
    
    # Variables for your project can go here
    # EXAMPLE_VAR = "value";
    
    # The shell hook runs when the environment is entered
    shellHook = ''
      # Flag to indicate we're in a nix-shell environment
      export DEVENV_NIX_SHELL=1
      
      # Project-specific environment variables (uncomment and customize)
      # export PROJECT_ROOT="$(pwd)"
      # export PATH="$PROJECT_ROOT/bin:$PATH"
      
      # ------------------------------------------------------
      # Display system info with nice styling
      # ------------------------------------------------------
      echo ""
      echo "🚀 $(tput bold)Development Environment Activated$(tput sgr0)"
      echo "📂 $(tput bold)$(pwd)$(tput sgr0)"
      echo ""
      macchina --theme nix
      
      # ------------------------------------------------------
      # Shell-specific setup
      # ------------------------------------------------------
      if [ -n "$NU_VERSION" ]; then
        echo "$(tput setaf 2)✨ Nushell detected - using Nushell configuration$(tput sgr0)"
        
        # We don't need to do much here because the nushell config
        # in ~/.config/nushell already handles aliases and environment setup
        
        # You can add Nushell-specific commands here if needed
        
      elif [ -n "$ZSH_VERSION" ]; then
        echo "$(tput setaf 2)✨ ZSH detected - loading ZSH utilities$(tput sgr0)"
        
        # ------------------------------------------------------
        # ZSH Utility loading
        # ------------------------------------------------------
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
          
          echo "$(tput setaf 2)✅ Loaded $sourced_count zsh utility scripts from $HOME/.config/zsh/extras$(tput sgr0)"
        fi
        
        # ------------------------------------------------------
        # ZSH Aliases and functions
        # ------------------------------------------------------
        
        # Navigation aliases
        alias ...="cd ../.."
        alias ..="cd .."
        alias ~="cd ~"
        
        # Development tools
        alias tf="terraform"
        
        # Import existing system aliases for specific tools
        if command -v code-insiders &>/dev/null; then
          alias code="code-insiders"
        fi
        
        if command -v kubecolor &>/dev/null; then
          alias kubectl="kubecolor"
          alias k="kubectl"
        fi
        
        if command -v eza &>/dev/null; then
          alias l="eza --icons=always -1"
          alias ll="eza --icons=always -1 -a"
          alias lt="eza --icons=always -1 -a -T"
        else
          # Fallback to ls if eza is not available
          alias l="ls -l"
          alias ll="ls -la"
        fi
        
        if command -v yazi &>/dev/null; then
          alias y="yazi"
        fi
        
        # ------------------------------------------------------
        # Custom functions
        # ------------------------------------------------------
        # Add your custom shell functions here
        
        # Example: find and edit a file
        # fe() { find . -name "*$1*" | fzf | xargs $EDITOR }
        
        echo "$(tput setaf 2)✅ Environment ready - happy coding!$(tput sgr0)"
      else
        # ------------------------------------------------------
        # Fallback for other shells (bash, etc.)
        # ------------------------------------------------------
        echo "$(tput setaf 3)📝 Standard shell detected$(tput sgr0)"
        
        # Basic aliases for navigation and common tools
        alias ...="cd ../.."
        alias ..="cd .."
        alias tf="terraform"
        
        if command -v eza &>/dev/null; then
          alias l="eza --icons=always -1"
          alias ll="eza --icons=always -1 -a"
          alias lt="eza --icons=always -1 -a -T"
        else
          alias l="ls -l"
          alias ll="ls -la"
        fi
        
        if command -v code-insiders &>/dev/null; then
          alias code="code-insiders"
        fi
        
        echo "$(tput setaf 2)✅ Environment ready - happy coding!$(tput sgr0)"
      fi
      
      # ------------------------------------------------------
      # Project-specific initialization (customize this section)
      # ------------------------------------------------------
      
      # Uncomment and modify these examples based on your project needs:
      
      # Initialize git hooks
      # if [ -d .git ]; then
      #   echo "Setting up Git hooks..."
      #   git config core.hooksPath .githooks
      # fi
      
      # Set up database connections
      # export DB_HOST=localhost
      # export DB_PORT=5432
      
      # Display project version from package.json
      # if [ -f package.json ]; then
      #   VERSION=$(cat package.json | jq -r '.version')
      #   echo "Project version: $VERSION"
      # fi
    '';
}