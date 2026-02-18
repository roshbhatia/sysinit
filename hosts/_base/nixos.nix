# Base configuration for all NixOS/Lima VM hosts
{ config, ... }:

{
  home-manager.users.${config.sysinit.user.username} = {
    # Packages auto-imported from:
    # - modules/home/packages/cli-tools.nix (curl, wget, htop, ripgrep, fd, bat, eza, jq, etc.)
    # - modules/home/packages/dev-tools.nix (Docker CLI, k8s tools, LSPs, formatters)
    # - modules/home/packages/language-managers.nix (rustup, uv, pipx)
    # Specific VMs can import language-runtimes.nix for system-wide runtimes

    programs.home-manager.enable = true;
  };
}
