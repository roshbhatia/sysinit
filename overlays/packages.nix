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
  firefox-addons = inputs.firefox-addons.packages.${system};
  goose-cli = unstable.goose-cli;
  nushell = unstable.nushell;
}
