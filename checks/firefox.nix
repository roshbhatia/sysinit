{
  pkgs,
  darwinConfigurations,
  nixosConfigurations,
}:
let
  configs = map (host: host.home-manager.users.${host.sysinit.user.username}) [
    darwinConfigurations.lv426.config
    nixosConfigurations.arrakis.config
  ];
  fixtures = pkgs.writeText "firefox-rendered.json" (
    builtins.toJSON (
      map (config: {
        chrome = config.programs.firefox.profiles.default.userChrome;
        content = config.programs.firefox.profiles.default.userContent;
        tridactyl = config.xdg.configFile."tridactyl/themes/stylix.css".text;
        newtab = config.home.file.".local/share/firefox/newtab.html".text;
        background = config.lib.stylix.colors.base00;
        policies = config.programs.firefox.policies;
      }) configs
    )
  );
in
pkgs.runCommand "firefox-theme-and-bindings-test"
  {
    nativeBuildInputs = [ pkgs.python3 ];
  }
  ''
    python3 ${./firefox.py} ${fixtures} ${../modules/home/programs/firefox/tridactylrc}
    touch "$out"
  ''
