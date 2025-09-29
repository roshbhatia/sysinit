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
  neovim-unwrapped = unstable.neovim-unwrapped;
  nix-your-shell = unstable.nix-your-shell;
  nushell = unstable.nushell;
  sbarlua = unstable.sbarlua;
}
