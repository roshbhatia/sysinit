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
              ;
          })
          (import ./packages {
            inherit
              config
              lib
              values
              pkgs
              ;
          })
        ];

        home = {
          stateVersion = "23.11";

          packages = [
            pkgs.bashInteractive
            pkgs.nu
            pkgs.zsh
          ];

          activation.setBash = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
            export PATH="${pkgs.bashInteractive}/bin:$PATH"
          '';
        };

        shell = pkgs.nu;
      };
  };
}

