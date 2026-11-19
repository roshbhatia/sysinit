{ pkgs, lib }:
let
  llmLib = import ../modules/home/programs/llm/lib { inherit lib; };
  defaults = import ../modules/home/programs/llm/gate-defaults.nix {
    rulesFile = "${llmLib.guards.rulesFile pkgs}";
    styleFile = "${pkgs.vale-styles}/vale.ini";
  };
  yamlFormat = pkgs.formats.yaml { };
  renderStep =
    step:
    {
      inherit (step) provider;
    }
    // lib.optionalAttrs (step ? match) { inherit (step) match; }
    // lib.optionalAttrs (step ? timeout) { inherit (step) timeout; }
    // lib.optionalAttrs (step ? args) { inherit (step) args; };
  configFile = yamlFormat.generate "gate-config.yaml" {
    version = "gate.config/v1";

    log = "@log@";
    providers.directory = "@providers@";
    defaults = {
      timeout = "2s";
      on_rewrite_unsupported = "deny";
    };
    chains = lib.mapAttrs (_event: steps: map renderStep steps) defaults.chains;
  };
  reviewFile = yamlFormat.generate "gate-review.yaml" defaults.review;
  gitAiGate = yamlFormat.generate "git-ai-gate.yaml" {
    version = "provider/v1";
    name = "git-ai-gate";
    description = "sysinit's git-ai checkpoint gate";
    command = [ "${pkgs.git-ai-gate}/bin/git-ai-gate" ];
    actions."gate.decide" = {
      description = "checkpoint";
      argv = [ "serve" ];
    };
    defaults.timeout = "10s";
  };
in
(import ./lib.nix { inherit pkgs; }) {
  name = "gate-config";
  script = "gate-config.nu";
  arguments = [
    "${pkgs.gate-providers}/share/gate/providers"
    gitAiGate
    configFile
    reviewFile
    "${pkgs.git}/bin/git"
  ];
  inputs = [
    pkgs.gate-cli
    pkgs.gate-providers
    pkgs.agent-notes
    pkgs.git
    pkgs.git-ai
    pkgs.git-ai-gate
  ];
}
