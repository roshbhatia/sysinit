{
  inputs,
  ...
}:

let

  patchHackShebangs =
    pkg:
    pkg.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        patchShebangs hack
      '';
    });
in

final: _prev:
let
  askExtras = inputs.ask.packages.${final.stdenv.hostPlatform.system}.extras;
  askProviders = askExtras.providers;
  tracesPackages = inputs.traces.packages.${final.stdenv.hostPlatform.system};
  tracesProviderPackages = final.lib.mapAttrs' (
    name: package: final.lib.nameValuePair (final.lib.removePrefix "provider-" name) package
  ) (final.lib.filterAttrs (name: _package: final.lib.hasPrefix "provider-" name) tracesPackages);

  tracesToolPackages = final.lib.mapAttrs' (
    name: package: final.lib.nameValuePair (final.lib.removePrefix "tool-" name) package
  ) (final.lib.filterAttrs (name: _package: final.lib.hasPrefix "tool-" name) tracesPackages);
in
{
  agent-signals-source = inputs.agent-signals.outPath;
  agent-state = inputs.agent-signals.packages.${final.stdenv.hostPlatform.system}.default;
  mkAgentNotifier = inputs.agent-signals.lib.mkNotifier;
  firefox-tabs = inputs.firefox-tabs.packages.${final.stdenv.hostPlatform.system}.default;
  worker = inputs.worker.packages.${final.stdenv.hostPlatform.system}.default;
  workspace-cli = inputs.changes.packages.${final.stdenv.hostPlatform.system}.ws;
  command-palette-source = inputs.command-palette.outPath;
  command-palette = inputs.command-palette.packages.${final.stdenv.hostPlatform.system}.default;
  firefox-addons = inputs.firefox-addons.packages.${final.stdenv.hostPlatform.system};
  claude-code = inputs.nix-claude-code.packages.${final.stdenv.hostPlatform.system}.default;
  orc-cli = inputs.orc-extras.packages.${final.stdenv.hostPlatform.system}.full;
  orc-providers = inputs.orc-extras.packages.${final.stdenv.hostPlatform.system}.all;
  ask-cli = patchHackShebangs inputs.ask.packages.${final.stdenv.hostPlatform.system}.default;
  ask-providers = final.symlinkJoin {
    inherit (askExtras) name;
    paths = final.lib.attrValues askProviders;
    passthru.providers = askProviders;
  };
  gate-cli = inputs.gate.packages.${final.stdenv.hostPlatform.system}.gate;

  gate-providers = inputs.gate.packages.${final.stdenv.hostPlatform.system}.extras;
  sysinit-wezterm-source = inputs.sysinit-wezterm.outPath;
  sysinit-wezterm-lua = inputs.sysinit-wezterm.lib.luaSource final;
  wezspawn = inputs.sysinit-wezterm.packages.${final.stdenv.hostPlatform.system}.wezspawn;
  sysinit-nvim-source = inputs.sysinit-nvim.outPath;
  hunk = inputs.hunk.packages.${final.stdenv.hostPlatform.system}.default;
  agent-notes = inputs.agent-notes.packages.${final.stdenv.hostPlatform.system}.default;
  agent-notes-nvim = inputs.agent-notes.packages.${final.stdenv.hostPlatform.system}.neovim-plugin;
  seshy-picker = inputs.seshy.packages.${final.stdenv.hostPlatform.system}.provider-wezterm;
  tether-picker = inputs.tether.packages.${final.stdenv.hostPlatform.system}.provider-wezterm;
  zoxide-picker = inputs.sysinit-wezterm.packages.${final.stdenv.hostPlatform.system}.provider-zoxide;
  zmx-picker = inputs.sysinit-wezterm.packages.${final.stdenv.hostPlatform.system}.provider-zmx;
  vale-styles = inputs.prose-style.packages.${final.stdenv.hostPlatform.system}.default;
  tether = inputs.tether.packages.${final.stdenv.hostPlatform.system}.default;
  citelock = inputs.citelock.packages.${final.stdenv.hostPlatform.system}.default;
  changes-cli = inputs.changes.packages.${final.stdenv.hostPlatform.system}.default;
  changes-providers = inputs.changes.packages.${final.stdenv.hostPlatform.system}.extras;
  changes-provider-git-notes =
    inputs.changes.packages.${final.stdenv.hostPlatform.system}.provider-git-notes;
  changes-neovim-plugin = inputs.changes.packages.${final.stdenv.hostPlatform.system}.neovim-plugin;
  seshy-cli = inputs.seshy.packages.${final.stdenv.hostPlatform.system}.default;
  specutil-cli = inputs.specutil.packages.${final.stdenv.hostPlatform.system}.full;
  traces-cli = tracesPackages.default;
  ere = inputs.ere.packages.${final.stdenv.hostPlatform.system}.default;
  traces-providers = tracesPackages.extras // {
    providers = tracesProviderPackages;
  };
  traces-tools = tracesToolPackages;
  slk = inputs.slk.packages.${final.stdenv.hostPlatform.system}.default.overrideAttrs (
    finalAttrs: old: {
      version = "0.23.0";
      src = inputs.slk;
      ldflags = (old.ldflags or [ ]) ++ [
        "-X=main.version=${finalAttrs.version}"
        "-X=main.commit=${inputs.slk.rev or "none"}"
        "-X=main.date=${inputs.slk.lastModifiedDate or "unknown"}"
      ];
    }
  );
  nuvim = patchHackShebangs inputs.nuvim.packages.${final.stdenv.hostPlatform.system}.default;

  nu-plugin-nuvim =
    final.runCommand "nu-plugin-nuvim-0.1.0"
      {
        meta.mainProgram = "nu_plugin_nuvim";
      }
      ''
        mkdir -p "$out/bin"
        ln -s ${final.nuvim}/bin/nu_plugin_nuvim "$out/bin/nu_plugin_nuvim"
      '';
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
