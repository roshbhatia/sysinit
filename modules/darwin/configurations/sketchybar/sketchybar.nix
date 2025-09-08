{
  config,
  lib,
  values,
  pkgs,
  ...
}:
{
  services.sketchybar = {
    package = pkgs.sketchybar;
    extraPackages = [ pkgs.sbarlua ];
    enable = true;

    config = ''
      #!/usr/bin/env lua

      require("init")
    '';
  };
}
