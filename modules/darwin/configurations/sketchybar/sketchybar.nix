{
  pkgs,
  ...
}:
let
  menus = pkgs.stdenv.mkDerivation {
    name = "menus";
    src = ../../../home/configurations/sketchybar/helpers/menus;

    buildPhase = ''
      make
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp ./bin/menus $out/bin/
    '';
  };

  monitor-reload-script = pkgs.writeShellScript "sketchybar-monitor-reload" ''
    PREV_HASH_FILE="/tmp/sketchybar-monitor-hash"
    current_hash=$(${pkgs.aerospace}/bin/aerospace list-monitors | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -d' ' -f1)
    if [ -f "$PREV_HASH_FILE" ]; then
        prev_hash=$(${pkgs.coreutils}/bin/cat "$PREV_HASH_FILE")
    else
        prev_hash=""
    fi

    if [ "$current_hash" != "$prev_hash" ]; then
        echo "$(${pkgs.coreutils}/bin/date): Monitor configuration changed, reloading sketchybar"
        ${pkgs.sketchybar}/bin/sketchybar --reload
        echo "$current_hash" > "$PREV_HASH_FILE"
    else
        echo "$(${pkgs.coreutils}/bin/date): No monitor changes detected"
    fi
  '';
in
{
  services.sketchybar = {
    package = pkgs.sketchybar;
    enable = true;
  };

  launchd.user.agents.sketchybar-monitor-reload = {
    serviceConfig = {
      ProgramArguments = [ "${monitor-reload-script}" ];
      RunAtLoad = true;
      StartInterval = 5;
      StandardOutPath = "/tmp/sketchybar-reload.log";
      StandardErrorPath = "/tmp/sketchybar-reload.error.log";
      EnvironmentVariables = {
        PATH = "${pkgs.coreutils}/bin:${pkgs.lib.makeBinPath [ pkgs.coreutils ]}:/usr/bin:/bin";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    sbarlua
    lua54Packages.cjson
    menus
  ];
}
