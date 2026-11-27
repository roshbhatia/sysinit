{ config, ... }:

{
  imports = [ ./options.nix ];

  programs.git = {
    enable = true;
    settings.user = { inherit (config.sysinit.git) name email; };
  };
}
