{ pkgs, lib, ... }: {
  # Anything installed here and not in modules/darwin is platform-agnostic
  home.packages = with pkgs; [
    # Core utilities
    atuin
    awscli
    bat
    colima
    coreutils
    direnv
    eza 
    fd
    ffmpeg
    fzf
    gh
    go
    gnugrep
    helm
    htop
    imagemagick
    jq
    jqp
    k9s
    kind
    kubecolor
    kustomize
    neovim
    poppler
    ripgrep
    sevenzip
    starship
    stern
    tfenv
    tmux
    tree
    watch
    wget
    yazi
    yq
    zoxide
    
    # Development
    python311
    nodejs
    git
    gnupg
    openssh
    nodePackages.typescript
    gopls
  ];
}