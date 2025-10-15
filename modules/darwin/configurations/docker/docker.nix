{
  pkgs,
  lib,
  values,
  ...
}:
let
  inherit (lib) mkIf;
  dockerEnabled = values.darwin.docker.enable or true;
in
{
  config = mkIf dockerEnabled {
    environment.systemPackages = with pkgs; [
      docker
      docker-compose
    ];
  };
}
