# Host-specific NixOS system configuration
{ config, ... }:

{
  # Import host-specific home-manager modules
  home-manager.users.${config.sysinit.user.username} = {
    imports = [
      ../home
    ];
  };

  # Host-specific system packages
  # environment.systemPackages = with pkgs; [ ];
}
