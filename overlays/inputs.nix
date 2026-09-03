{
  inputs,
  ...
}:

let
  # A check phase that runs a hack/ script hits its /usr/bin/env shebang, which
  # the Darwin sandbox resolves and the Linux one does not. Drop each call once
  # the input patches its own shebangs.
  patchHackShebangs =
    pkg:
    pkg.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        patchShebangs hack
      '';
    });
in

final: _prev: {
  firefox-addons = inputs.firefox-addons.packages.${final.stdenv.hostPlatform.system};
  claude-code = inputs.nix-claude-code.packages.${final.stdenv.hostPlatform.system}.default;
  orc-cli = inputs.orc.packages.${final.stdenv.hostPlatform.system}.default;
  orc-providers = inputs.orc.packages.${final.stdenv.hostPlatform.system}.extras;
  ask-cli = patchHackShebangs inputs.ask.packages.${final.stdenv.hostPlatform.system}.default;
  ask-providers = inputs.ask.packages.${final.stdenv.hostPlatform.system}.extras;
  changes-cli = inputs.changes.packages.${final.stdenv.hostPlatform.system}.default;
  changes-providers = inputs.changes.packages.${final.stdenv.hostPlatform.system}.extras;
  seshy-cli = inputs.seshy.packages.${final.stdenv.hostPlatform.system}.default;
  specutil-cli = inputs.specutil.packages.${final.stdenv.hostPlatform.system}.default;
  traces-cli = inputs.traces.packages.${final.stdenv.hostPlatform.system}.default;
  traces-provider-claude = inputs.traces.packages.${final.stdenv.hostPlatform.system}.provider-claude;
  traces-provider-codex = inputs.traces.packages.${final.stdenv.hostPlatform.system}.provider-codex;
  traces-provider-opencode =
    inputs.traces.packages.${final.stdenv.hostPlatform.system}.provider-opencode;
  slk = inputs.slk.packages.${final.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    ldflags = (old.ldflags or [ ]) ++ [
      "-X=main.version=0.16.0"
      "-X=main.commit=${inputs.slk.rev or "none"}"
      "-X=main.date=${inputs.slk.lastModifiedDate or "unknown"}"
    ];
  });
  nuvim = patchHackShebangs inputs.nuvim.packages.${final.stdenv.hostPlatform.system}.default;
  # Upstream nu-plugin symlinks the unpatched nuvim, so overriding it reaches
  # nothing. The symlink is rebuilt here against the patched package.
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
