{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Core utilities
    coreutils
    curl
    findutils
    gettext
    gnugrep
    gnused
    openssh
    tree
    unzip
    watch
    wget
    which
    zip

    # Text processing & search
    bat
    eza
    fd
    jq
    jqp
    ripgrep
    yq-go

    # System monitoring
    duf
    htop

    # Git tools
    delta
    gh
    git
    git-crypt
    git-filter-repo
    libgit2

    # Shell essentials
    gum
    nix-your-shell
    oh-my-posh

    # Terminal utilities
    chafa
    glow
    imagemagick
    mods
    tokei
  ];
}
