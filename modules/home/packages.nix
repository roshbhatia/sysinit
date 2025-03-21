{ pkgs, lib, ... }: {
  # Let Nix properly manage core packages across various language ecosystems
  home.packages = with pkgs; [
    # Core CLI utilities
    bat
    eza 
    fd
    ripgrep
    jq
    
    # Languages & Runtimes
    python311
    nodejs
    go
    
    # Development tools
    git
    gh  # GitHub CLI
    gnupg
    openssh
    
    # Core development packages
    nodePackages.typescript
    
    # Go packages
    gopls
  ];
}