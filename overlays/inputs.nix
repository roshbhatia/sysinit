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

  # The spec-change projection CLI. It also provides `specutil check`, the
  # deterministic rubric-lint the spec-driven schema and the
  # adversarial-review skill both require on PATH.
  specutil = inputs.specutil.packages.${final.stdenv.hostPlatform.system}.default;

  # The session manager behind `sy`. NOT added to home.packages directly: the
  # readiness gate in modules/home/programs/llm/runtime/default.nix is what
  # installs a binary named `sy`, and it execs this store path. Installing both
  # would collide on bin/sy in one profile.
  seshy = inputs.seshy.packages.${final.stdenv.hostPlatform.system}.default;
}
