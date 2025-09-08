{
  config,
  pkgs,
  ...
}:
let
  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
  path = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/sketchybar";
in
{
  xdg.configFile."sketchybar/sketchybarrc".text = ''
    #!/usr/bin/env lua

    package.cpath = package.cpath .. ";/Users/" .. os.getenv("USER") .. "/.local/share/sketchybar_lua/?.so"

    sbar = require("sketchybar")

    sbar.add("item", "test_item", { label = { string = "Hello, world!" } })

    sbar.event_loop()
  '';

  xdg.configFile."sketchybar/lua".source = mkOutOfStoreSymlink "${path}/lua";
}
