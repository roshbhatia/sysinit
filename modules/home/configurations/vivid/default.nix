{ config, lib, ... }:

{
  xdg.configFile = {
    "vivid/themes/kanagawa-wave.yml".source = ./themes/kanagawa-wave.yml;
    "vivid/themes/kanagawa-dragon.yml".source = ./themes/kanagawa-dragon.yml;
  };
}
