{ pkgs }:
let
  nativeCheck = import ../lib/native.nix { inherit pkgs; };
in
nativeCheck {
  name = "hammerspoon-startup-test";
  inputs = [ pkgs.lua5_4 ];
  commands = [
    [
      "lua"
      ./hammerspoon-switcher.lua
      ../../modules/darwin/home/hammerspoon/lua/sysinit/pkg/core/init.lua
    ]
    [
      "lua"
      ./hammerspoon-startup.lua
      ../../modules/darwin/home/hammerspoon/lua/sysinit/pkg/core/startup.lua
    ]
  ];
}
