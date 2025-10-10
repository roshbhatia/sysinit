{
  config,
  pkgs,
  lib,
  values,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  
  dockerEnabled = values.darwin.docker.enable or false;
  backend = values.darwin.docker.backend or "colima";
in
{
  config = mkIf dockerEnabled {
    environment.systemPackages = with pkgs; [
      docker
      docker-compose
    ];
  };
}
