{ pkgs, lib, ... }:

{
  # These are installed at the system level when Homebrew is disabled
  systemPackages = with pkgs; [
    argocd
    ansible
    caddy
    colima
    direnv
    eza
    fd
    glow
    gum
    gettext
    helm
    oh-my-posh
    kubectl
    kubecolor
    k9s
    lazygit
    libgit2
    luajit
    nil
    nixfmt-rfc-style
    nushell
    ripgrep
    screenresolution
    shellcheck
    socat
    sshpass
    tailscale
    go-task
    yazi
  ];
}
