# overlays/crossplane.nix
# Purpose: pin crossplane-cli to a specific nixpkgs revision.
{ ... }:

final: _prev:
let
  crossplane-1-17-1 = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/882842d2a908700540d206baa79efb922ac1c33d.tar.gz";
    sha256 = "105v2h9gpaxq6b5035xb10ykw9i3b3k1rwfq4s6inblphiz5yw7q";
  }) { system = final.system; };
in
{
  inherit (crossplane-1-17-1) crossplane-cli;
}
