{
  username,
  values,
  ...
}:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.${username} =
      {
        config,
        pkgs,
        lib,
        utils,
        ...
      }:
      {
        imports = [
          (import ./configurations {
            inherit
              config
              lib
              values
              pkgs
              utils
              ;
          })
          (import ./packages {
            inherit
              config
              lib
              values
              pkgs
              utils
              ;
          })
        ];

        xdg = {
          enable = true;
          cacheHome = "${config.home.homeDirectory}/.cache";
          configHome = "${config.home.homeDirectory}/.config";
          dataHome = "${config.home.homeDirectory}/.local/share";
          stateHome = "${config.home.homeDirectory}/.local/state";
        };

        home = {
          sessionVariables = {
            HOME = config.home.homeDirectory;
            XDG_CACHE_HOME = config.xdg.cacheHome;
            XDG_CONFIG_HOME = config.xdg.configHome;
            XDG_DATA_HOME = config.xdg.dataHome;
            XDG_STATE_HOME = config.xdg.stateHome;
            XCA = config.xdg.cacheHome;
            XCO = config.xdg.configHome;
            XDA = config.xdg.dataHome;
            XST = config.xdg.stateHome;
          };
          stateVersion = "23.11";

          packages = [
            pkgs.bashInteractive
          ];

          activation.setBash = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
            export PATH="${pkgs.bashInteractive}/bin:$PATH"
          '';
        };
      };
  };
}
