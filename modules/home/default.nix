{
  config,
  lib,
  pkgs,
  username,
  overlay,
  ...
}:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.${username} =
      { ... }:
      {
        imports = [
          (import ./packages {
            inherit
              config
              lib
              overlay
              pkgs
              ;
          })
          (import ./configurations {
            inherit
              config
              lib
              overlay
              pkgs
              ;
          })
        ];
        home = {
          stateVersion = "23.11";
        };
      };
  };
}
