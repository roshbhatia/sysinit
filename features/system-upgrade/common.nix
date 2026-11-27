{ inputs, pkgs, ... }:

{
  services.comin = {
    package = inputs.comin.packages.${pkgs.stdenv.hostPlatform.system}.comin;
    exporter.listen_address = "127.0.0.1";
  };
}
