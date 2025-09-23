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
  nur = {
    repos = {
      rycee = {
        firefox-addons = inputs.firefox-addons.packages.${system};
      };
    };
  };
  cursor-cli = unstable.cursor-cli;
  neovim-unwrapped = unstable.neovim-unwrapped;
  nushell = unstable.nushell;
  sbarlua = unstable.sbarlua;
}
