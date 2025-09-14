{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    bash
    bat
    coreutils
    curl
    fd
    findutils
    git
    gnugrep
    gnused
    nix-output-monitor
    ripgrep
    wget
    which
    zsh
  ];
}
