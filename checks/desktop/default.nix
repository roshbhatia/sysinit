{
  pkgs,
  homeConfigurations,
  darwinConfigurations,
  nixosConfigurations,
}:
let
  nuCheck = import ../lib/nushell.nix { inherit pkgs; };
  nativeCheck = import ../lib/native.nix { inherit pkgs; };
  evalOnly = name: pkgs.runCommand name { } "touch $out";
in
{
  sunshine-apps = nuCheck {
    name = "sunshine-apps-check";
    script = ./sunshine-apps.nu;
    arguments = [ ../../modules/nixos/home/sunshine-apps-gen.nu ];
    inputs = [
      pkgs.curl
      pkgs.imagemagick
    ];
  };

  notification-assets = import ./notification-assets.nix { inherit pkgs; };

  firefox = import ./firefox.nix { inherit pkgs darwinConfigurations nixosConfigurations; };

  url-routing = nativeCheck {
    name = "url-routing-test";
    inputs = [ pkgs.lua5_4 ];
    commands = [
      [
        "lua"
        ./url-routing.lua
        ../../modules/darwin/home/hammerspoon/lua/sysinit/pkg/url_routing.lua
      ]
    ];
  };

  macos-notifier = nuCheck {
    name = "macos-notifier-test";
    script = ./macos-notifier.nu;
    arguments = [
      ../../modules/home/programs/llm/runtime/macos-notifier.sh
      ../fixtures/notifier-command.nu
    ];
    inputs = [ pkgs.bash ];
  };

  hammerspoon-startup = import ./hammerspoon-startup.nix { inherit pkgs; };

  jankyborders =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.jankyborders
    else
      evalOnly "jankyborders-not-applicable";

  nixos-launcher = import ./nixos-launcher.nix {
    inherit pkgs;
    home = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config;
  };
}
