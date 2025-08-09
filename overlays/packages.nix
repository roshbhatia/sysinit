{
  inputs,
  system,
  ...
}:

final: _prev:
let
  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config = final.config;
  };
in
{
  nushell = unstable.nushell;
  firefox-addons = inputs.firefox-addons.packages.${system};
}
