{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    bash
    coreutils
    curl
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
