{
  inputs,
  ...
}:

final: _prev: {
  firefox-addons = inputs.firefox-addons.packages.${final.stdenv.hostPlatform.system};
  claude-code = inputs.nix-claude-code.packages.${final.stdenv.hostPlatform.system}.default;
  nur = {
    repos = {
      rycee = {
        firefox-addons = inputs.firefox-addons.packages.${final.stdenv.hostPlatform.system};
      };
      inherit (inputs.nur.legacyPackages.${final.stdenv.hostPlatform.system}.repos) charmbracelet;
    };
  };

  inherit (inputs.cupcake.packages.${final.stdenv.hostPlatform.system}) cupcake-cli;

  # The overlay entry is what gives `checks/` a route to hunk. The home module
  hunk = inputs.hunk.packages.${final.stdenv.hostPlatform.system}.hunk;

  specutil = inputs.specutil.packages.${final.stdenv.hostPlatform.system}.default;

  seshy = inputs.seshy.packages.${final.stdenv.hostPlatform.system}.default;
}
