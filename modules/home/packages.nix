{ pkgs, lib, ... }: {
  home.packages = with pkgs; [
    atuin
    awscli
    bat
    coreutils
    docker
    fzf
    gettext
    gh
    git
    gnugrep
    gnupg
    go
    gopls
    htop
    jq
    jqp
    kind
    kustomize
    nodejs
    nodePackages.typescript
    openssh
    stern
    swift
    tree
    watch
    wget
    yq
  ];
  
  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];
}
