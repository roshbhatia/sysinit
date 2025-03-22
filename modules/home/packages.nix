{ pkgs, lib, ... }: {
  # Anything installed here and not in modules/darwin is platform-agnostic
  home.packages = with pkgs; [
    bat
    eza 
    fd
    ripgrep
    jq
    
    python311
    nodejs
    go
    
    git
    gh
    gnupg
    openssh
    
    nodePackages.typescript
    
    gopls
  ];
}