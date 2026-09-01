{
  inputs,
  ...
}:

final: _prev: {
  firefox-addons = inputs.firefox-addons.packages.${final.stdenv.hostPlatform.system};
  claude-code = inputs.nix-claude-code.packages.${final.stdenv.hostPlatform.system}.default;
  orc-cli = inputs.orc.packages.${final.stdenv.hostPlatform.system}.default;
  ask-cli = inputs.ask.packages.${final.stdenv.hostPlatform.system}.default;
  changes-cli = inputs.changes.packages.${final.stdenv.hostPlatform.system}.default;
  seshy-cli = inputs.seshy.packages.${final.stdenv.hostPlatform.system}.default;
  specutil-cli = inputs.specutil.packages.${final.stdenv.hostPlatform.system}.default;
  traces-cli = inputs.traces.packages.${final.stdenv.hostPlatform.system}.default;
  nuvim = inputs.nuvim.packages.${final.stdenv.hostPlatform.system}.default;
  nu-plugin-nuvim = inputs.nuvim.packages.${final.stdenv.hostPlatform.system}.nu-plugin;
  nvim-nu = inputs.nuvim.packages.${final.stdenv.hostPlatform.system}.nvim-plugin;
  nur = {
    repos = {
      rycee = {
        firefox-addons = inputs.firefox-addons.packages.${final.stdenv.hostPlatform.system};
      };
      inherit (inputs.nur.legacyPackages.${final.stdenv.hostPlatform.system}.repos) charmbracelet;
    };
  };

  inherit (inputs.cupcake.packages.${final.stdenv.hostPlatform.system}) cupcake-cli;
}
