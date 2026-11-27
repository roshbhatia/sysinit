{ inputs, ... }:

{
  imports = [
    inputs.comin.nixosModules.comin
    ./common.nix
    ./public-remote.nix
  ];

  services.comin.enable = true;
}
