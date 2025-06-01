{
  config,
  lib,
  pkgs,
  username,
  homeDirectory,
  ...
}:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.${username} =
      { pkgs, ... }:
      {
        imports = [
          ./packages
          ./configurations
        ];
        home = {
          inherit username homeDirectory;
          stateVersion = "23.11";
        };
      };
  };
}
