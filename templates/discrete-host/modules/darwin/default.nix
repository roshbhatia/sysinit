# Host-specific Darwin system configuration
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

  # Host-specific homebrew packages (in addition to those in hostCommon)
  # homebrew.brews = [ ];
  # homebrew.casks = [ ];
}
