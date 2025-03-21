{ pkgs, lib, ... }: {
  # Since we're managing most packages via homebrew, we'll keep this minimal
  # and only include packages that are better managed through Nix
  home.packages = with pkgs; [
    # CLI tools
    bat
    bottom # better top/htop
    direnv
    eza # better ls
    fd # better find
    ripgrep # better grep
    
    # Development tools
    nodejs
    yarn
    
    # System tools
    htop
    
    # Other utilities
    gnupg
    jq
    yq
  ];
}
