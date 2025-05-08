{ config, lib, pkgs, ... }:

{
  xdg.configFile."wezterm" = {
    source = .;
    force = true;
  };
}
