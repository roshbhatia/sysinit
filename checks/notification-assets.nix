{ pkgs }:
let
  inherit (pkgs) lib;
in
pkgs.runCommand "notification-assets"
  {
    nativeBuildInputs = [
      pkgs.nushell
      pkgs.libxml2
      pkgs.librsvg
    ];
  }
  ''
    nu --no-config-file ${./notification-assets.nu} \
      ${../modules/home/programs/llm/runtime/check-icons.nu} \
      ${../modules/home/programs/llm/runtime/notifier-plist.nu} \
      ${lib.getExe pkgs.nushellPlugins.formats}
    touch "$out"
  ''
