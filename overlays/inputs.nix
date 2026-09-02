{
  inputs,
  ...
}:

final: _prev: {
  firefox-addons = inputs.firefox-addons.packages.${final.stdenv.hostPlatform.system};
  claude-code = inputs.nix-claude-code.packages.${final.stdenv.hostPlatform.system}.default;
  orc-cli = inputs.orc.packages.${final.stdenv.hostPlatform.system}.default;
  orc-provider-changes = inputs.orc.packages.${final.stdenv.hostPlatform.system}.provider-changes;
  orc-provider-harness = inputs.orc.packages.${final.stdenv.hostPlatform.system}.provider-harness;
  orc-provider-traces = inputs.orc.packages.${final.stdenv.hostPlatform.system}.provider-traces;
  orc-provider-wezterm = inputs.orc.packages.${final.stdenv.hostPlatform.system}.provider-wezterm;
  orc-provider-zmx = inputs.orc.packages.${final.stdenv.hostPlatform.system}.provider-zmx;
  ask-cli = inputs.ask.packages.${final.stdenv.hostPlatform.system}.default;
  changes-cli = inputs.changes.packages.${final.stdenv.hostPlatform.system}.default;
  changes-provider-ast-grep =
    inputs.changes.packages.${final.stdenv.hostPlatform.system}.provider-ast-grep;
  changes-provider-calldiff =
    inputs.changes.packages.${final.stdenv.hostPlatform.system}.provider-calldiff;
  seshy-cli = inputs.seshy.packages.${final.stdenv.hostPlatform.system}.default;
  specutil-cli = inputs.specutil.packages.${final.stdenv.hostPlatform.system}.default;
  traces-cli = inputs.traces.packages.${final.stdenv.hostPlatform.system}.default;
  traces-provider-claude = inputs.traces.packages.${final.stdenv.hostPlatform.system}.provider-claude;
  traces-provider-codex = inputs.traces.packages.${final.stdenv.hostPlatform.system}.provider-codex;
  traces-provider-opencode =
    inputs.traces.packages.${final.stdenv.hostPlatform.system}.provider-opencode;
  nuvim = inputs.nuvim.packages.${final.stdenv.hostPlatform.system}.default;
  nu-plugin-nuvim = inputs.nuvim.packages.${final.stdenv.hostPlatform.system}.nu-plugin;
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
