# lima-dev - Full development VM
{ pkgs, config, ... }:

{
  imports = [
    ../_base/lima.nix
  ];

  home-manager.users.${config.sysinit.user.username} = {
    # Additional dev-full packages
    home.packages = with pkgs; [
      nodejs
      python3
      rustc
      cargo
      go
      delta
      yq
      gnumake
      cmake
      docker-compose
    ];
  };
}
