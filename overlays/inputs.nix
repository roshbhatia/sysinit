{
  inputs,
  ...
}:

final: _prev: {
  firefox-addons = inputs.firefox-addons.packages.${final.system};
  nur = {
    repos = {
      rycee = {
        firefox-addons = inputs.firefox-addons.packages.${final.system};
      };
      inherit (inputs.nur.legacyPackages.${final.system}.repos) charmbracelet;
    };
  };

  inherit (inputs.cupcake.packages.${final.system}) cupcake-cli;
}
