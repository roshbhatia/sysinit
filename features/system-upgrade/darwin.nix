{
  inputs,
  hostname,
  lib,
  ...
}:

{
  imports = [
    inputs.comin.darwinModules.comin
    ./common.nix
  ];

  services.comin.hostname = lib.mkDefault hostname;
}
