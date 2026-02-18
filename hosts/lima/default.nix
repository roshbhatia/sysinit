# lima-dev - Full development VM
{ pkgs, config, ... }:

{
  imports = [
    ../_base/lima.nix
  ];

  home-manager.users.${config.sysinit.user.username} = {
    # Full dev environment (no language runtimes - projects specify via shell.nix)
    home.packages = with pkgs; [
      # Build tools
      gnumake
      cmake

      # Utilities
      delta
      yq

      # Docker CLI tools (for use with shareDockerFromHost)
      docker
      docker-buildx
      docker-compose
    ];
  };
}
