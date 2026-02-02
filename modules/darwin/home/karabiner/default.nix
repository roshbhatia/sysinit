{ config, ... }:

{
  xdg.configFile."karabiner/karabiner.json".source =
    config.lib.file.mkOutOfStoreSymlink ./karabiner.json;
}
