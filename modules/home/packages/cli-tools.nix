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
    gh-dash
    git
    git-crypt
    git-filter-repo
    lazygit
    libgit2
    tig

    # Shell essentials
    argc
    direnv
    fzf
    gum
    nix-your-shell
    oh-my-posh
    zoxide
    zsh

    # Terminal utilities
    asciinema
    asciinema-agg
    chafa
    diffnav
    glow
    imagemagick
    mods
    tlrc
    tokei
  ];
}
