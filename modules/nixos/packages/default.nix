{ pkgs, ... }:
{
  # System-wide packages
  environment.systemPackages = with pkgs; [
    # Essential tools
    vim
    git
    wget
    curl
    htop
    tmux

    # Network tools
    tailscale

    # System tools
    pciutils
    usbutils
  ];
}
