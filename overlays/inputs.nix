{
  inputs,
  ...
}:

final: _prev: {
  nur = {
    repos = {
      inherit (inputs.nur.legacyPackages.${final.system}.repos) charmbracelet;
    };
  };

  neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${final.system}.default;

  cupcake-cli = inputs.cupcake.packages.${final.system}.cupcake-cli;
}
