# Host-specific home-manager configuration
{ ... }:

{
  imports = [
    # Add host-specific home modules here
    # ./custom-tool
  ];

  # Host-specific dotfiles
  # xdg.configFile = {
  #   "some-tool/config".source = ./some-tool/config;
  # };
}
