{
  pkgs,
  ...
}:
let
  menus = pkgs.stdenv.mkDerivation {
    name = "menus";
    src = ../../home/configurations/sketchybar/helpers/menus;

    buildInputs = with pkgs.darwin.apple_sdk.frameworks; [ Carbon SkyLight ];

    buildPhase = ''
      make
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp ./bin/menus $out/bin/
    '';
  };
in
{
  services.sketchybar = {
    package = pkgs.sketchybar;
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    sbarlua
    luajitPackages.cjson
    menus
  ];
}
